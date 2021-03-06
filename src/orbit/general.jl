#== # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Functions to compute general values related to the orbit.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ==#

export @check_orbit
export angvel, dArgPer, dRAAN, period

################################################################################
#                                  Overloads
################################################################################

function copy(orb::Orbit)
    Orbit(orb.t, orb.a, orb.e, orb.i, orb.Ω, orb.ω, orb.f)
end

function display(orb::Orbit)
    # Definition of colors that will be used for printing.
    b = "\x1b[1m"
    d = "\x1b[0m"
    g = "\x1b[1m\x1b[32m"
    y = "\x1b[1m\x1b[33m"

    # Print the TLE information.
    println()
    print("                 $(g)Orbit$(d)\n")
    print("$(y)  ======================================$(d)\n")
    print("$(b)                  t = $(d)"); @printf("%14.5f\n",    orb.t)
    print("$(b)    Semi-major axis = $(d)"); @printf("%13.4f km\n", orb.a/1000)
    print("$(b)       Eccentricity = $(d)"); @printf("%15.6f\n",    orb.e)
    print("$(b)        Inclination = $(d)"); @printf("%13.4f ˚\n",  orb.i*180/pi)
    print("$(b)               RAAN = $(d)"); @printf("%13.4f ˚\n",  orb.Ω*180/pi)
    print("$(b)    Arg. of Perigee = $(d)"); @printf("%13.4f ˚\n",  orb.ω*180/pi)
    print("$(b)       True Anomaly = $(d)"); @printf("%13.4f ˚\n",  orb.f*180/pi)
end

################################################################################
#                                    Macros
################################################################################

"""
### macro check_orbit(a, e)

Verify if the orbit with semi-major axis `a` and eccentricity `e` is valid. This
macro throws an exception if the orbit is not valid.

# Args

* `a`: Semi-major axis [m].
* `e`: Eccentricity.

"""
macro check_orbit(a, e)
    quote
        # Check if the arguments are valid.
        if $(esc(a)) < 0
            throw(ArgumentError("The semi-major axis must be greater than 0."))
        end

        if !( 0 <= $(esc(e)) < 1 )
            throw(ArgumentError("The eccentricity must be within the interval 0 <= e < 1."))
        end

        # Compute the orbit perigee and check if it is inside Earth.
        perigee = $(esc(a))*(1-$(esc(e)))

        if perigee < R0
            throw(ArgumentError("The orbit perigee ($perigee m) is inside Earth!"))
        end
    end
end


################################################################################
#                                  Functions
################################################################################

"""
    function Orbit(a::Number, e::Number, i::Number, Ω::Number, ω::Number, f::Number)

Create an orbit with semi-major axis `a`, eccentricity `e`, inclination `i`,
right ascension of the ascending node `Ω`, argument of perigee `ω`, and true
anomaly `f`.

# Args

* `a`: Semi-major axis [m].
* `e`: Eccentricity.
* `i`: Inclination [rad].
* `Ω`: Right ascension of the ascending node [rad].
* `ω`: Argument of perigee [rad].
* `f`: True anomaly [rad].

# Returns

An object of type `Orbit` with the specified orbit. The orbit epoch is defined
as 0.0.

"""
function Orbit(a::Number, e::Number, i::Number, Ω::Number, ω::Number, f::Number)
    Orbit(0.0, a, e, i, Ω, ω, f)
end

################################################################################
#                                  Functions
################################################################################

"""
    function angvel(a::Number, e::Number, i::Number, pert::Symbol = :J2)

Compute the angular velocity of an object in an orbit with semi-major axis `a`,
eccentricity `e`, and inclination `i`, using the perturbation terms specified by
the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `a`: Semi-major axis [m].
* `e`: Eccentricity.
* `i`: Inclination [rad].
* `pert`: (OPTIONAL) Symbol that defines the perturbation (**Default** = `:J2`).

# Returns

The angular velocity of an object in the specified orbit [rad/s].

"""
function angvel(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    # Unperturbed orbit period.
    n0 = sqrt(m0/Float64(a)^3)

    # Perturbation computed using a Keplerian orbit.
    if pert == :J0
        return n0
    # Perturbation computed using perturbations terms up to J2.
    elseif pert == :J2
        # Semi-lactum rectum.
        p = a*(1.0-e^2)

        # Orbit period considering the perturbations (up to J2).
        return n0 + 3.0*R0^2*J2/(4.0*p^2)*n0*(sqrt(1.0-e^2)*(3.0*cos(i)^2-1.0) +
                                              (5.0*cos(i)^2-1.0))
    else
        throw(ArgumentError("The perturbation parameter $pert is not defined."))
    end

end

"""
    function angvel(orb::Orbit, pert::Symbol = :J2)

Compute the angular velocity of an object in an orbit `orb` using the
perturbation terms specified by the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `orb`: Orbit (see `Orbit`).
* `pert`: (OPTIONAL) Symbol that defines the perturbation (**Default** = `:J2`).

# Returns

The angular velocity of an object in the specified orbit [rad/s].

"""
function angvel(orb::Orbit, pert::Symbol = :J2)
    angvel(orb.a, orb.e, orb.i, pert)
end

"""
    function dArgPer(a::Number, e::Number, i::Number, pert::Symbol = :J2)

Compute the time-derivative of the argument of perigee of an orbit with
semi-major axis `a`, eccentricity `e`, and inclination `i`, using the
perturbation terms specified by the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `a`: Semi-major axis [m].
* `e`: Eccentricity.
* `i`: Inclination [rad].
* `pert`: (OPTIONAL) Symbol that defines the perturbation (**Default** = `:J2`).

# Returns

The perturbation of the argument of perigee [rad/s].

"""
function dArgPer(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    # Perturbation computed using a Keplerian orbit.
    if pert == :J0
        return 0.0
    # Perturbation computed using perturbations terms up to J2.
    elseif pert == :J2
        # Semi-lactum rectum.
        p = a*(1.0-e^2)

        # Unperturbed orbit period.
        n0 = angvel(a, e, i, :J0)

        # Perturbation of the argument of perigee.
        return 3.0*R0^2*J2/(4.0*p^2)*n0*(5.0*cos(i)^2-1.0)
    else
        throw(ArgumentError("The perturbation parameter $pert is not defined."))
    end

end

"""
    function dArgPer(orb::Orbit, pert::Symbol = :J2)

Compute the time-derivative of the argument of perigee of an orbit `orb` using
the perturbation terms specified by the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `orb`: Orbit (see `Orbit`).
* `pert`: (OPTIONAL) Symbol that defines the perturbation (**Default** = `:J2`).

# Returns

The perturbation of the argument of perigee [rad/s].

"""
function dArgPer(orb::Orbit, pert::Symbol = :J2)
    dArgPer(org.a, org.e, orb.i, pert)
end

"""
    function dRAAN(a::Number, e::Number, i::Number, pert::Symbol = :J2)

Compute the time-derivative of the right ascension of the ascending node of an
orbit with semi-major axis `a`, eccentricity `e`, and inclination `i`, using the
perturbation terms specified by the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `a`: Semi-major axis [m].
* `e`: Eccentricity.
* `i`: Inclination [rad].
* `pert`: Symbol that defines the perturbation (Default = `:J2`).

# Returns

The time derivative of the RAAN [rad/s].

"""
function dRAAN(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    # Perturbation computed using a Keplerian orbit.
    if pert == :J0
        return 0.0
    # Perturbation computed using perturbations terms up to J2.
    elseif pert == :J2
        # Semi-lactum rectum.
        p = a*(1.0-e^2)

        # Unperturbed orbit period.
        n0 = angvel(a, e, i, :J0)

        # Perturbation of the right ascension of the ascending node.
        return -3.0/2.0*R0^2/(p^2)*n0*J2*cos(i)
    else
        throw(ArgumentError("The perturbation parameter $pert is not defined."))
    end
end

"""
    function dRAAN(orb::Orbit, pert::Symbol = :J2)

Compute the time-derivative of the right ascension of the ascending node of an
orbit `orb` using the perturbation terms specified by the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `orb`: Orbit (see `Orbit`).
* `pert`: Symbol that defines the perturbation (Default = `:J2`).

# Returns

The time derivative of the RAAN [rad/s].

"""
function dRAAN(orb::Orbit, pert::Symbol = :J2)
    dRAAN(orb.a, orb.e, orb.i, pert)
end

"""
    function period(a::Number, e::Number, i::Number, pert::Symbol = :J2)

Compute the period of an object in an orbit with semi-major axis `a`,
eccentricity `e`, and inclination `i`, using the perturbation terms specified by
the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `a`: Semi-major axis [m].
* `e`: Eccentricity.
* `i`: Inclination [rad].
* `pert`: (OPTIONAL) Symbol that defines the perturbation (**Default** = `:J2`).

# Returns

The orbit period [s].

"""
function period(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    n = angvel(a, e, i, pert)
    2.0*pi/n
end

"""
    function period(orb::Orbit, pert::Symbol = :J2)

Compute the period of an object in an orbit `orb` using the perturbation terms
specified by the symbol `pert`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

# Args

* `orb`: Orbit (see `Orbit`).
* `pert`: (OPTIONAL) Symbol that defines the perturbation (**Default** = `:J2`).

# Returns

The orbit period [s].

"""
function period(orb::Orbit, pert::Symbol = :J2)
    period(orb.a, orb.e, orb.i, pert)
end
