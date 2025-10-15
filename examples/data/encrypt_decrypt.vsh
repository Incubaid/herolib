#!/usr/bin/env -S v -n -w -gc none -cg  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.crypt.aes_symmetric { decrypt, encrypt }
import incubaid.herolib.ui.console

msg := 'my message'.bytes()
console.print_debug('${msg}')

secret := '1234'
encrypted := encrypt(msg, secret)
console.print_debug('${encrypted}')

decrypted := decrypt(encrypted, secret)
console.print_debug('${decrypted}')

assert decrypted == msg
