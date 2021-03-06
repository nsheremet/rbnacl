# encoding: binary
# frozen_string_literal: true

module RbNaCl
  module GroupElements
    # Points provide the interface to NaCl's Curve25519 high-speed elliptic
    # curve cryptography, which can be used for implementing Diffie-Hellman
    # and other forms of public key cryptography (e.g. RbNaCl::Box)
    #
    # Objects of the Point class represent points on Edwards curves. NaCl
    # defines a base point (the "standard group element") which we can
    # multiply by an arbitrary integer. This is how NaCl computes public
    # keys from private keys.
    class Curve25519
      # NaCl's Curve25519 base point (a.k.a. standard group element), serialized as hex
      STANDARD_GROUP_ELEMENT = ["0900000000000000000000000000000000000000000000000000000000000000"].pack("H*").freeze

      # Order of the standard group
      STANDARD_GROUP_ORDER = 2**252 + 27_742_317_777_372_353_535_851_937_790_883_648_493

      # Degenerate key (all-zeroes, results in an all-zero shared secret)
      DEGENERATE_KEY = ("\0" * 32).freeze

      include KeyComparator
      include Serializable

      extend Sodium

      sodium_type :scalarmult
      sodium_primitive :curve25519

      sodium_function :scalarmult_curve25519,
                      :crypto_scalarmult_curve25519,
                      %i[pointer pointer pointer]

      # Number of bytes in a scalar on this curve
      SCALARBYTES = 32
      BYTES       = 32

      # Number of bytes in a scalar on this curve

      # Creates a new Point from the given serialization
      #
      # @param [String] point location of a group element (32-bytes)
      #
      # @return [RbNaCl::Point] the Point at this location
      def initialize(point)
        @point = point.to_str

        raise CryptoError, "degenerate key detected" if @point == DEGENERATE_KEY

        # FIXME: really should have a separate constant here for group element size
        # Group elements and scalars are both 32-bits, but that's for convenience
        Util.check_length(@point, SCALARBYTES, "group element")
      end

      # Multiply the given integer by this point
      # This ordering is a bit confusing because traditionally the point
      # would be the right-hand operand.
      #
      # @param [String] integer value to multiply with this Point (32-bytes)
      #
      # @return [RbNaCl::Point] result as a Point object
      def mult(integer)
        integer = integer.to_str
        Util.check_length(integer, SCALARBYTES, "integer")

        result = Util.zeros(SCALARBYTES)

        raise CryptoError, "degenerate key detected" unless self.class.scalarmult_curve25519(result, integer, @point)
        self.class.new(result)
      end

      # Return the point serialized as bytes
      #
      # @return [String] 32-byte string representing this point
      def to_bytes
        @point
      end

      @base_point = new(STANDARD_GROUP_ELEMENT)

      # NaCl's standard base point for all Curve25519 public keys
      #
      # @return [RbNaCl::Point] standard base point (a.k.a. standard group element)
      def self.base
        # TODO: better support fixed-based scalar multiplication (this glosses over native support)
        @base_point
      end
      class << self
        attr_reader :base_point
      end
    end
  end
end
