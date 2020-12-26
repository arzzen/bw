# Bash Bitcoin brain wallet inspector

A brainwallet refers to the concept of storing Bitcoins in one's own mind by memorization of a passphrase. As long as the passphrase is not recorded anywhere, the Bitcoins can be thought of as existing nowhere except in the mind of the holder. If a brainwallet is forgotten or the person dies or is permanently incapacitated, the Bitcoins are lost forever.

A brainwallet is created simply by starting with a unique phrase. The phrase must be sufficiently long to prevent brute-force guessing - a short password, a simple phrase, or a phrase taken from published literature is likely to be stolen by hackers who use computers to quickly try combinations. A suggestion is to take a memorable phrase and change it in a silly way that is difficult to predict.

#### Install

```bash
git clone git@github.com:arzzen/bw.git
cd bw && ./bw.sh -p "your-password"
```

Requires packages: `dc, openssl, perl, sed, cat, printf`

#### Usage

- simple usage: `./bw.sh -p password`
- show help: `./bw.sh -h`
- show version: `./bw.sh -v`
- with balance: `./bw.sh -b -p password`
- json output: `./bw.sh -j -p password`
- with balance & json output: `./bw.sh -j -b -p password`
- more complex: see [batch example](example/README.md)

#### Screenshots

![imgraw](https://user-images.githubusercontent.com/6382002/103156505-71400c00-47a9-11eb-8808-8eb1e6c90d13.png)

![imgjson](https://user-images.githubusercontent.com/6382002/103156476-28885300-47a9-11eb-9529-39676e3c1ce2.png)

#### Steps I recommend:

1. Disconnect your computer from Internet, WIFI etc (physically) and make sure nobody stand near your display.
2. Imagine a password and generate your wallet using `./bw.sh -p "really-complex-password"`.
3. Write down the `address_uncompressed` - it's your Bitcoin address.
4. Destroy your computer or zero-fill your disk a number of times and re-install your OS.

Voila! You may now send money to your brain wallet even though your computer never touched Internet. Should be safe from
any kind of digital threat such as keyboard sniffer, virus, trojan etc.

#### Your wallet

- can't get stolen physically but they get kick yor ass to extract the password from you (so create several)
- may get brute forced in the future but you could renew your password every year or more frequent

#### Donate me

> Donate to [bc1qw6q6v3lxqe3kz6glhcmuh4fx7zq0kcp2jk6la7](https://www.blockchain.com/btc/payment_request?address=bc1qw6q6v3lxqe3kz6glhcmuh4fx7zq0kcp2jk6la7&amount=0.00025) to see more development!
