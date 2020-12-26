#!/bin/bash

#
# Bitcoin Brain Wallet Inspector
#
_APP_VERSION="v0.3.0"

# Application defaults
# 0=off (default) / 1=on
_APP_BALANCE=0 
_APP_JSON=0

#
# Show version
#
showVersion()
{
    echo "Version: ${_APP_VERSION}"
}

#
# Show help
#
showHelp()
{
    echo ""
    echo "Usage: bw.sh [-b -j -p \"pass\"]"
    echo 
    echo "  -b Show Bitcoin address balance (optional)"
    echo "  -j Show as JSON output (optional)"
    echo "  -p <arg> Brain wallet password in clear text (require)"
    echo "  -v Show version"
    echo ""
    echo "You can use this tool to inspect your (or others) brain wallets."
    echo "Make sure you use an complex password if you decide to use this."
    echo ""
    echo "Known brain wallets are: sausage, fuckyou"
    echo ""
}

#
# Show app version
#
showAppVersion()
{
    showVersion
    exit 0
}

#
# Inspect brain wallet
#
brainWalletInspect()
{
    res="{"
    declare -a base58=(
          1 2 3 4 5 6 7 8 9
        A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
        a b c d e f g h i j k   m n o p q r s t u v w x y z
    )
    unset dcr; for i in {0..57}; do dcr+="${i}s${base58[i]}"; done
    declare ec_dc='
    I16i7sb0sa[[_1*lm1-*lm%q]Std0>tlm%Lts#]s%[Smddl%x-lm/rl%xLms#]s~
    483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
    79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
    2 100^d14551231950B75FC4402DA1732FC9BEBF-so1000003D1-ddspsm*+sGi
    [_1*l%x]s_[+l%x]s+[*l%x]s*[-l%x]s-[l%xsclmsd1su0sv0sr1st[q]SQ[lc
    0=Qldlcl~xlcsdscsqlrlqlu*-ltlqlv*-lulvstsrsvsulXx]dSXxLXs#LQs#lr
    l%x]sI[lpSm[+q]S0d0=0lpl~xsydsxd*3*lal+x2ly*lIx*l%xdsld*2lx*l-xd
    lxrl-xlll*xlyl-xrlp*+Lms#L0s#]sD[lpSm[+q]S0[2;AlDxq]Sdd0=0rd0=0d
    2:Alp~1:A0:Ad2:Blp~1:B0:B2;A2;B=d[0q]Sx2;A0;B1;Bl_xrlm*+=x0;A0;B
    l-xlIxdsi1;A1;Bl-xl*xdsld*0;Al-x0;Bl-xd0;Arl-xlll*x1;Al-xrlp*+L0
    s#Lds#Lxs#Lms#]sA[rs.0r[rl.lAxr]SP[q]sQ[d0!<Qd2%1=P2/l.lDxs.lLx]
    dSLxs#LPs#LQs#]sM[lpd1+4/r|]sR
    ';

    #
    # Password
    #
    PASSWORD=$1
    res=$res"\"password_clear_text\": \"${PASSWORD}\","

    #
    # Compute BTC private key
    #
    PASSWORD_SHA256=`echo -n "${PASSWORD}" | sha256sum | awk '{print $1}'`
    res=$res"\"password_SHA256\": \"$PASSWORD_SHA256\","

    PASSWORD_SHA256_EXT="80${PASSWORD_SHA256}"
    res=$res"\"password_SHA256_extended\": \"$PASSWORD_SHA256_EXT\","

    PASSWORD_SHA256_EXT_SHA256=`echo -n "${PASSWORD_SHA256_EXT}" | xxd -r -p | sha256sum -b | awk '{print $1}'`
    res=$res"\"password_SHA256_extended_SHA256\": \"$PASSWORD_SHA256_EXT_SHA256\","

    PASSWORD_SHA256_EXT_SHA256_CHECKSUM=`echo -n "${PASSWORD_SHA256_EXT_SHA256}" | xxd -r -p | sha256sum -b | awk '{print $1}'`
    res=$res"\"password_checksum_SHA256_extended_SHA256\": \"$PASSWORD_SHA256_EXT_SHA256_CHECKSUM\","

    PASSWORD_SHA256_EXT_SHA256_CHECKSUM_HEAD=`echo -n "${PASSWORD_SHA256_EXT_SHA256_CHECKSUM}" | cut -b -8`
    res=$res"\"password_checksum_head_SHA256_extended_SHA256\": \"$PASSWORD_SHA256_EXT_SHA256_CHECKSUM_HEAD\","

    PRIVATE_KEY_BASE16="${PASSWORD_SHA256_EXT}${PASSWORD_SHA256_EXT_SHA256_CHECKSUM_HEAD}"
    res=$res"\"private_key_base16\": \"$PRIVATE_KEY_BASE16\","

    encodeBase58() {
        dc -e "16i ${1^^} [3A ~r d0<x]dsxx +f" |
        while read -r n; do echo -n "${base58[n]}"; done
    }
    PRIVATE_KEY_BASE58=`encodeBase58 $PRIVATE_KEY_BASE16`
    res=$res"\"private_key_base58\": \"${PRIVATE_KEY_BASE58}\","

    #
    # Compute BTC address
    #
    SECRET_EXPONENT="${PASSWORD_SHA256}"
    res=$res"\"secret_exponent\": \"${SECRET_EXPONENT}\","

    checksum() {
        perl -we "print pack 'H*', '$1'" |
        openssl dgst -sha256 -binary |
        openssl dgst -sha256 -binary |
        perl -we "print unpack 'H8', join '', <>"
    }
    hexToAddress() {
        local version=${2:-00} x="$(printf "%${3:-40}s" $1 | sed 's/ /0/g')"
        printf "%34s\n" "$(encodeBase58 "$version$x$(checksum "$version$x")")" |
        {
        if ((version == 0))
        then sed -r 's/ +/1/'
        else cat
        fi
        }
    }
    hash160() {
        openssl dgst -sha256 -binary |
        openssl dgst -rmd160 -binary |
        perl -we "print unpack 'H*', join '', <>"
    }

    PUBLIC_KEY_X_AND_Y=`dc -e "$ec_dc lG I16i${SECRET_EXPONENT^^}ri lMx 16olm~ n[ ]nn"`
    #res=$res  \"Public keys (Y & X)\": \"${PUBLIC_KEY_X_AND_Y}\","

    PUBLIC_KEY_X=`echo ${PUBLIC_KEY_X_AND_Y} | awk '{print $2}'`
    res=$res"\"public_key_X\": \"${PUBLIC_KEY_X}\","

    PUBLIC_KEY_Y=`echo ${PUBLIC_KEY_X_AND_Y} | awk '{print $1}'`
    res=$res"\"public_key_Y\": \"${PUBLIC_KEY_Y}\","

    WIF_COMPRESSED="$(hexToAddress "${SECRET_EXPONENT}01" 80 66)"
    res=$res"\"wallet_import_format_WIF_compressed\": \"${WIF_COMPRESSED}\","

    WIF_UNCOMPRESSED="$(hexToAddress "${SECRET_EXPONENT}" 80 64)"
    res=$res"\"wallet_import_format_WIF_uncompressed\": \"${WIF_UNCOMPRESSED}\","

    if [[ "$PUBLIC_KEY_Y" =~ [02468ACE]$ ]]
    then y_parity="02"
    else y_parity="03"
    fi
    ADDRESS_COMPRESSED="$(hexToAddress "$(perl -e "print pack q(H*), q($y_parity$PUBLIC_KEY_X)" | hash160)")"
    res=$res"\"address_compressed\": \"${ADDRESS_COMPRESSED}\","

    ADDRESS_UNCOMPRESSED="$(hexToAddress "$(perl -e "print pack q(H*), q(04$PUBLIC_KEY_X$PUBLIC_KEY_Y)" | hash160)")"
    res=$res"\"address_uncompressed\": \"${ADDRESS_UNCOMPRESSED}\""

    #
    # Balance
    #
    if [ "$_APP_BALANCE" -eq 1 ]; then
        res=$res","
        res=$res"\"blockchain_URL\": \"blockchain.com/btc/address/${ADDRESS_UNCOMPRESSED}\","
        res=$res"\"blockchain_API\": \"api.blockcypher.com/v1/btc/main/addrs/${ADDRESS_UNCOMPRESSED}\","
            
        if [ -n "$BLOCKCYPHER_TOKEN" ]; then
            API_URL="https://api.blockcypher.com/v1/btc/main/addrs/${ADDRESS_UNCOMPRESSED}/balance?token=$BLOCKCYPHER_TOKEN"
        else
            API_URL="https://api.blockcypher.com/v1/btc/main/addrs/${ADDRESS_UNCOMPRESSED}/balance"
        fi

        BTC_BALANCE=`curl -s "$API_URL" | jq .final_balance`
        balance=$(echo "$BTC_BALANCE/100000000" | bc -l)

        BTC_RECEIVED=`curl -s "$API_URL" | jq .total_received`
        received=$(echo "$BTC_RECEIVED/100000000" | bc -l)

        res=$res"\"balance_BTC_sat\": \"${BTC_BALANCE}\","
        res=$res"\"balance_BTC\": \"${balance}\","
        res=$res"\"received_BTC_sat\": \"${BTC_RECEIVED}\","
        res=$res"\"received_BTC\": \"${received}\""
    fi
    res=$res"}"

    if [ "$_APP_JSON" -eq 1 ]; then
        echo $res
    else
        pad='----------------------------------------------------'
        lines=`echo $res | tr -d '{} "' | tr ',' '\n'`
        for line in $lines
        do
            string1=`echo $line | cut -d ":" -f 1`
            string2=`echo $line | cut -d ":" -f 2`
            printf "%s %s $string2\n" $string1 "${pad:${#string1}}"
            string2=${string2:1}
        done
    fi
}

#
# Parse command-line arguments
#
while getopts "h?vbjp:" opt; do
    case "$opt" in
        b)
            _APP_BALANCE=1
            ;;
        j)
            _APP_JSON=1
            ;;
        h|\?)
            showHelp
            exit 0
            ;;
        v)
            showAppVersion
            exit 0
            ;;
        p)
            brainWalletInspect "$OPTARG"
            exit 0
            ;;
    esac
done

