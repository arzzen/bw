#!/bin/bash

#
# Bitcoin Brain wallet inspector
#
_APP_VERSION="v0.2.0"

# Application defaults
_APP_TRANSACTION=0 # 0=off (default) / 1=on

#
# Show app head
#
showAppHead()
{
    echo "\"version\": \"${_APP_VERSION}\","
}

#
# Show app help
#
showAppHelp()
{
    showAppHead
    echo "Usage: brainwalletinspect [-ptv]"
    echo "  -p <arg> Brain wallet password in clear text"
    echo "  -t Show Bitcoin address balance"
    echo "  -v Show version"
    echo ""
    echo "You can use this tool to inspect your (or others) brain wallets. Make sure you use an "
    echo "complex password if you decide to use this."
    echo ""
    echo "Known brain wallets are: sausage, fuckyou"
}

#
# Show app version
#
showAppVersion()
{
    echo "{"
    showAppHead
    echo "}"
    exit 0
}

#
# Inspect brain wallet
#
brainWalletInspect()
{
    echo "{"
    showAppHead
    #echo "Inspecting brain wallet: ${1}"
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
    echo "\"password_clear_text\": \"${PASSWORD}\","

    #
    # Compute BTC private key
    #
    PASSWORD_SHA256=`echo -n "${PASSWORD}" | sha256sum | awk '{print $1}'`
    echo "\"password_SHA256\": \"$PASSWORD_SHA256\","

    PASSWORD_SHA256_EXT="80${PASSWORD_SHA256}"
    echo "\"password_SHA256_extended\": \"$PASSWORD_SHA256_EXT\","

    PASSWORD_SHA256_EXT_SHA256=`echo -n "${PASSWORD_SHA256_EXT}" | xxd -r -p | sha256sum -b | awk '{print $1}'`
    echo "\"password_SHA256_extended_SHA256\": \"$PASSWORD_SHA256_EXT_SHA256\","

    PASSWORD_SHA256_EXT_SHA256_CHECKSUM=`echo -n "${PASSWORD_SHA256_EXT_SHA256}" | xxd -r -p | sha256sum -b | awk '{print $1}'`
    echo "\"password_checksum_SHA256_extended_SHA256\": \"$PASSWORD_SHA256_EXT_SHA256_CHECKSUM\","

    PASSWORD_SHA256_EXT_SHA256_CHECKSUM_HEAD=`echo -n "${PASSWORD_SHA256_EXT_SHA256_CHECKSUM}" | cut -b -8`
    echo "\"password_checksum_head_SHA256_extended_SHA256\": \"$PASSWORD_SHA256_EXT_SHA256_CHECKSUM_HEAD\","

    PRIVATE_KEY_BASE16="${PASSWORD_SHA256_EXT}${PASSWORD_SHA256_EXT_SHA256_CHECKSUM_HEAD}"
    echo "\"private_key_base16\": \"$PRIVATE_KEY_BASE16\","

    encodeBase58() {
        dc -e "16i ${1^^} [3A ~r d0<x]dsxx +f" |
        while read -r n; do echo -n "${base58[n]}"; done
    }
    PRIVATE_KEY_BASE58=`encodeBase58 $PRIVATE_KEY_BASE16`
    echo "\"private_key_base58\": \"${PRIVATE_KEY_BASE58}\","

    #
    # Compute BTC address
    #
    SECRET_EXPONENT="${PASSWORD_SHA256}"
    echo "\"secret_exponent\": \"${SECRET_EXPONENT}\","

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
    #echo "  \"Public keys (Y & X)\":                                  \"${PUBLIC_KEY_X_AND_Y}\","

    PUBLIC_KEY_X=`echo ${PUBLIC_KEY_X_AND_Y} | awk '{print $2}'`
    echo "\"public_key_X\": \"${PUBLIC_KEY_X}\","

    PUBLIC_KEY_Y=`echo ${PUBLIC_KEY_X_AND_Y} | awk '{print $1}'`
    echo "\"public_key_Y\": \"${PUBLIC_KEY_Y}\","

    WIF_COMPRESSED="$(hexToAddress "${SECRET_EXPONENT}01" 80 66)"
    echo "\"wallet_import_format_WIF_compressed\": \"${WIF_COMPRESSED}\","

    WIF_UNCOMPRESSED="$(hexToAddress "${SECRET_EXPONENT}" 80 64)"
    echo "\"wallet_import_format_WIF_uncompressed\": \"${WIF_UNCOMPRESSED}\","

    if [[ "$PUBLIC_KEY_Y" =~ [02468ACE]$ ]]
    then y_parity="02"
    else y_parity="03"
    fi
    ADDRESS_COMPRESSED="$(hexToAddress "$(perl -e "print pack q(H*), q($y_parity$PUBLIC_KEY_X)" | hash160)")"
    echo "\"address_compressed\": \"${ADDRESS_COMPRESSED}\","

    ADDRESS_UNCOMPRESSED="$(hexToAddress "$(perl -e "print pack q(H*), q(04$PUBLIC_KEY_X$PUBLIC_KEY_Y)" | hash160)")"
    echo "\"address_uncompressed\": \"${ADDRESS_UNCOMPRESSED}\","

    #
    # Transactions
    #
    if [ "$_APP_TRANSACTION" -eq 1 ]; then
        BTC_RECEIVED=`GET https://blockchain.info/q/addressbalance/${ADDRESS_UNCOMPRESSED}`
        echo "\"blockchain_URL\": \"https://www.blockchain.com/btc/address/${ADDRESS_UNCOMPRESSED}\","
        echo "\"blockchain_API\": \"https://api.blockcypher.com/v1/btc/main/addrs/${ADDRESS_UNCOMPRESSED}\","
            
        if [ -n "$BLOCKCYPHER_TOKEN" ]; then
            API_URL="https://api.blockcypher.com/v1/btc/main/addrs/${ADDRESS_UNCOMPRESSED}/balance?token=$BLOCKCYPHER_TOKEN"
        else
            API_URL="https://api.blockcypher.com/v1/btc/main/addrs/${ADDRESS_UNCOMPRESSED}/balance"
        fi

        BTC_BALANCE=`curl -s "$API_URL" | jq .final_balance`
        balance=$(echo "$BTC_BALANCE/100000000" | bc -l)
        echo "\"balance_BTC_sat\": \"${BTC_BALANCE}\","
        echo "\"balance_BTC\": \"${balance}\""
    fi

    echo "}"
}

#
# Parse command-line arguments
#
while getopts "h?vtp:" opt; do
    case "$opt" in
        transaction|t)
            _APP_TRANSACTION=1
            ;;
        help|h|\?)
            showAppHelp
            exit 0
            ;;
        version|v)
            showAppVersion
            exit 0
            ;;
        password|p)
            brainWalletInspect $OPTARG
            exit 0
            ;;
    esac
done

