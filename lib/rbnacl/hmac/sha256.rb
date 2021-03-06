# encoding: binary
# frozen_string_literal: true

module RbNaCl
  module HMAC
    # Computes an authenticator as HMAC-SHA-256
    #
    # The authenticator can be used at a later time to verify the provenance of
    # the message by recomputing the HMAC over the message and then comparing it to
    # the provided authenticator.  The class provides methods for generating
    # signatures and also has a constant-time implementation for checking them.
    #
    # This is a secret key authenticator, i.e. anyone who can verify signatures
    # can also create them.
    #
    # @see http://nacl.cr.yp.to/auth.html
    class SHA256 < Auth
      extend Sodium

      sodium_type :auth
      sodium_primitive :hmacsha256
      sodium_constant :BYTES
      sodium_constant :KEYBYTES

      sodium_function :auth_hmacsha256_init,
                      :crypto_auth_hmacsha256_init,
                      %i[pointer pointer size_t]

      sodium_function :auth_hmacsha256_update,
                      :crypto_auth_hmacsha256_update,
                      %i[pointer pointer ulong_long]

      sodium_function :auth_hmacsha256_final,
                      :crypto_auth_hmacsha256_final,
                      %i[pointer pointer]

      # Create instance without checking key length
      #
      # RFC 2104 HMAC
      # The key for HMAC can be of any length.
      #
      # see https://tools.ietf.org/html/rfc2104#section-3
      def initialize(key)
        @key = Util.check_hmac_key(key, "#{self.class} key")
      end

      private

      def compute_authenticator(authenticator, message)
        state = State.new

        self.class.auth_hmacsha256_init(state, key, key.bytesize)
        self.class.auth_hmacsha256_update(state, message, message.bytesize)
        self.class.auth_hmacsha256_final(state, authenticator)
      end

      # libsodium crypto_auth_hmacsha256_verify works only for 32 byte keys
      # ref: https://github.com/jedisct1/libsodium/blob/master/src/libsodium/crypto_auth/hmacsha256/auth_hmacsha256.c#L109
      def verify_message(authenticator, message)
        correct = Util.zeros(BYTES)
        compute_authenticator(correct, message)
        Util.verify32(correct, authenticator)
      end
    end

    # The crupto_auth_hmacsha256_state struct representation
    # ref: jedisct1/libsodium/src/libsodium/include/sodium/crypto_auth_hmacsha256.h
    class SHA256State < FFI::Struct
      layout :state, [:uint32, 8],
             :count, :uint64,
             :buf, [:uint8, 64]
    end

    # The crypto_hash_sha256_state struct representation
    # ref: jedisct1/libsodium/src/libsodium/include/sodium/crypto_hash_sha256.h
    class State < FFI::Struct
      layout :ictx, SHA256State,
             :octx, SHA256State
    end
  end
end
