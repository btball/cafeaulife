_ = require('underscore')

root = this

#########################
# The Grand-daddy class #
#########################

class Square

###########################################
# Indivisibles represent individual cells #
###########################################

class Indivisible extends Square
  constructor: (@hash) ->
  toValue: ->
    @hash
  to_json: ->
    [@hash]

##################################################################################
# Divisible is the parent for Size two, four, and larger ("non-trivial") squares #
##################################################################################

class Divisible extends Square
  constructor: ({@nw, @ne, @se, @sw}) ->
    @hash = Square.hash(this)
    Square.add(this)
  to_json: ->
    a =
      nw: @nw.to_json()
      ne: @ne.to_json()
      se: @se.to_json()
      sw: @sw.to_json()
    b =
      top: _.map( _.zip(a.nw, a.ne), (row) ->
        [left, right] = row
        if _.isArray(left)
          left.concat(right)
        else
          row
      )
      bottom: _.map( _.zip(a.sw, a.se), (row) ->
        [left, right] = row
        if _.isArray(left)
          left.concat(right)
        else
          row
      )
    b.top.concat(b.bottom)

#####################################################
# Non-Trivial squares are eight and larger in size. #
#####################################################

NonTrivialSquare = do ->

  this_to_intermediate_components = ->
    nw: @nw.result
    ne: @ne.result
    se: @se.result
    sw: @sw.result
    nn: Square
      .find_or_create
        nw: @nw.ne
        ne: @ne.nw
        se: @ne.sw
        sw: @nw.se
      .result
    ee: Square
      .find_or_create
        nw: @ne.sw
        ne: @ne.se
        se: @se.ne
        sw: @se.nw
      .result
    ss: Square
      .find_or_create
        nw: @sw.ne
        ne: @se.nw
        se: @se.sw
        sw: @sw.se
      .result
    ww: Square
      .find_or_create
        nw: @nw.sw
        ne: @nw.se
        se: @se.ne
        sw: @se.nw
      .result
    cc: Square
      .find_or_create
        nw: @nw.se
        ne: @ne.sw
        se: @se.nw
        sw: @sw.ne
      .result

  intermediate_components_to_result_components = ->
    nw: Square
      .find_or_create
        nw: @nw
        ne: @nn
        se: @cc
        sw: @ww
      .result
    ne: Square
      .find_or_create
        nw: @nn
        ne: @ne
        se: @ee
        sw: @cc
      .result
    se: Square
      .find_or_create
        nw: @cc
        ne: @ee
        se: @se
        sw: @ss
      .result
    sw: Square
      .find_or_create
        nw: @ww
        ne: @cc
        se: @ss
        sw: @sw
      .result

  class NonTrivialSquare extends Divisible
    constructor: ({nw, ne, se, sw}) ->
      super({nw: nw, ne:ne, se:se, sw:sw})
      intermediate_square_components = this_to_intermediate_components.call(this)
      result_square_components = intermediate_components_to_result_components.call(intermediate_square_components)
      @result = Square.find_or_create(result_square_components)
      @velocity = @nw.velocity * 2

#############################################
# Various hash and cache methods for Square #
#############################################

do (Square) ->

  num_buckets = 7919
  buckets = []

  Square.hash = (square_like) ->
    if square_like.hash?
      square_like.hash
    else
      ((3 * Square.hash(square_like.nw)) + (9 * Square.hash(square_like.ne))  + (27 * Square.hash(square_like.se)) + (81 * Square.hash(square_like.sw)))

  Square.find = (square_params) ->
    bucket_number = Square.hash(square_params) % num_buckets
    if buckets[bucket_number]?
      _.find buckets[bucket_number], (sq) ->
        sq.nw is square_params.nw and sq.ne is square_params.ne and sq.se is square_params.se and sq.sw is square_params.sw

  Square.find_or_create = (square_params) ->
    found = Square.find(square_params)
    if found
      found
    else
      new NonTrivialSquare(square_params)

  Square.add = (square) ->
    bucket_number = square.hash % num_buckets
    (buckets[bucket_number] ||= []).push(square)

#########
# Seeds #
#########

do ->

  Indivisible.Alive = new Indivisible(1)
  Indivisible.Dead = new Indivisible(0)

  size_twos = do ->
    class SquareSz2 extends Divisible
    dead_or_alive = [Indivisible.Dead, Indivisible.Alive]
    [0..15].map (n) ->
      new SquareSz2
        nw: dead_or_alive[(n&8)>>3]
        ne: dead_or_alive[(n&4)>>2]
        se: dead_or_alive[(n&2)>>1]
        sw: dead_or_alive[n&1]

  class SquareSz4 extends Divisible
    constructor: ({nw, ne, se, sw, @result}) ->
      super({nw: nw, ne:ne, se:se, sw:sw})
      @velocity = 1
  [
    [ 0,  0,  0,  0, 0],
    # ...
    [15, 15, 15, 15, 0]
  ].forEach ([nw, ne, se, sw, result]) ->
    new SquareSz4
      nw: size_twos[nw]
      ne: size_twos[ne]
      se: size_twos[se]
      sw: size_twos[sw]
      result: size_twos[result]

root.cafeaulife = {Square, Indivisible, NonTrivialSquare}