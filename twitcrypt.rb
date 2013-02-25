#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
# twitcrypt - a method for sending secure tweets.
# Copyright 2012 - Adam Caudill <adam@adamcaudill.com>
#

require 'openssl'
require 'digest/sha2'
require 'rubygems'
require 'highline/import'

CHAR_BASE = 0x4e00
SET_LOW_MASK = 0b00001111
SET_HIGH_MASK = 0b11110000
READ_LOW_MASK = 0b0000000011111111
READ_HIGH_MASK = 0b0000111100000000

def encode(msg)
  final_msg = ""

  bytes = msg.bytes.to_a
  last = 0
  bytes.each_with_index do |c, i|
    #fix this, hack to skip(3), as we only need to run
    # every third entry
    next if i < last  unless last == 0

    high_value = ((bytes[i+1] & SET_HIGH_MASK) >> 4) * 256
    low_value = (bytes[i+1] & SET_LOW_MASK) * 256
 
    char_1 = [CHAR_BASE+bytes[i] + high_value].pack('U*')
    char_2 = [CHAR_BASE+bytes[i+2] + low_value].pack('U*')

    final_msg += char_1
    final_msg += char_2
    last = i + 3
  end

  return final_msg
end

def decode(msg)
  final_msg = ""

  last = 0
  chars = msg.scan(/./)
  chars.each_with_index do |c, i|
    #fix this, hack to skip(2), as we only need to run
    # every second entry
    next if i < last  unless last == 0

    base_1 = chars[i].unpack('U*')[0] - CHAR_BASE
    base_2 = chars[i+1].unpack('U*')[0] - CHAR_BASE

    high_value = ((base_1 & READ_HIGH_MASK) >> 8)
    low_value = ((base_2 & READ_HIGH_MASK) >> 8)

    char_1 = [base_1 - (high_value*256)].pack('c*')

    char_2_val = 0
    char_2_val = (char_2_val & SET_LOW_MASK) | (high_value << 4)
    char_2_val = (char_2_val & SET_HIGH_MASK) | low_value
    char_2 = [char_2_val].pack('c*')

    char_3 = [base_2 - (low_value*256)].pack('c*')

    final_msg += char_1
    final_msg += char_2
    final_msg += char_3
    last = i + 2
  end

  return final_msg
end

def encrypt(msg, ivSeed, key)
  sha256 = Digest::SHA2.new(256)
  aes = OpenSSL::Cipher.new("AES-256-CBC")
  
  aes.encrypt
  aes.key = (key + sha256.digest(key)).slice(0, 32)
  aes.iv = sha256.digest(key + ivSeed).slice(0, 16)
  aes.padding = 0
  
  data = aes.update(msg) + aes.final

  return data
end

def decrypt(msg, ivSeed, key)
  sha256 = Digest::SHA2.new(256)
  aes = OpenSSL::Cipher.new("AES-256-CBC")

  aes.decrypt
  aes.key = (key + sha256.digest(key)).slice(0, 32)
  aes.iv = sha256.digest(key + ivSeed).slice(0, 16)
  aes.padding = 0

  data = aes.update(msg) + aes.final

  return data
end

def getIvSeed()
  (0...6).map{65.+(rand(25)).chr}.join
end

def get_password(prompt="Enter Encryption Key:")
  ask(prompt) {|q| q.echo = false}
end

def perform_decrypt_base(input, password)
  decoded = decode(input)
  
  ivSeed = decoded.slice(0, 6)
  decrypted = decrypt(decoded.slice(6, 144), ivSeed, password)
  decrypted.strip!

  return decrypted
end

def perform_decrypt_tweet(url, password)
  #TODO: Get tweet content
end

def perform_encrypt_base(message, password)
  while message.length < 144 do
    message += " "
  end

  ivSeed = getIvSeed
  encrypted = encrypt(message, ivSeed, password)
  encoded = encode(ivSeed + encrypted)

  return encoded
end

def usage()
  puts "  ./twitcrypt -dt <tweet url> - Get's the content of the tweet and decrypts it. Doesn't work at the moment"
  puts "  ./twitcrypt -ed - This is primarily for testing; displays the encrypted message."
  puts "  ./twitcrypt -dd <message - optional> - This is primarily for testing; decrypts the message."
  
  #exit with an error
  exit(-1)
end

def main()
  puts "twitcrypt - Encrypted Twitter Communications"
  puts "Copyright (c) 2013 Adam Caudill <adam@adamcaudill.com>"
  puts "EXPERIMENTAL - This is experimental, do not use for sensitive data!"
  puts ""
  
  case ARGV[0]
    when "-dt"
      usage if ARGV.count != 2
        
      puts "Message: " + perform_decrypt_tweet(ARGV[1], get_password)
    when "-dd"
      if ARGV.count == 1
        message = ask("Message:")
      else if ARGV.count == 2
        message = ARGV[1]
      else
        usage
      end
        
      puts perform_decrypt_base(message, get_password)
    when "-ed"
      usage if ARGV.count != 1
        
      puts perform_encrypt_base(ask("Message:"), get_password)
    else
      usage
    end
end

main

