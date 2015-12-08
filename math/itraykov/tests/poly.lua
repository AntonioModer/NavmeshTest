local poly = require("code.math.itraykov.poly")

-- test
local l = { 1,2, 3,4, 5,6, 7,8 }
local r = { 7,8, 5,6, 3,4, 1,2 }
poly.reverse(l)
local lsz = table.concat(l)
local rsz = table.concat(r)
assert(lsz == rsz)

local tri = { -1,0, 0,1, 1,0 }
assert(not poly.ccw(tri))

local tri2 = { 1,0, 0,1, -1,0 }
assert(poly.ccw(tri2))

local cv = { -1,-1, -1,1, 1,1, 1,-1 }
assert(not poly.ccw(cv))
assert(poly.convex(cv))
poly.reverse(cv)
assert(poly.ccw(cv))
assert(poly.convex(cv))

local cc = { -1,-1, -1,1, 0,0, 1,1, 1,-1 }
assert(not poly.ccw(cc))
assert(not poly.convex(cc))
poly.reverse(cc)
assert(poly.ccw(cc))
assert(not poly.convex(cc))

assert(poly.point(cc, 0, -0.5))
assert(not poly.point(cc, 10, 10))
poly.reverse(cc)
assert(poly.point(cc, 0, -0.5))
assert(not poly.point(cc, 10, 10))

local si = { -1,0, 1,0, 0,1, 0,-1 }
assert(not poly.simple(si))
local si = { -1,0, 1,0, 0,1, -2,0, 0,-1 }
assert(poly.simple(si))
assert(not poly.convex(si))
local star = { 250,75, 323,301, 131,161, 369,161, 177,301 }
assert(not poly.simple(star))
