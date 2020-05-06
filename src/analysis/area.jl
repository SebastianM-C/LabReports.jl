function sign_change(x, sgn::Pair{Symbol,Symbol})
    if sgn == (:- => :+)
        idx = sign_change(x, true)
    else
        idx = sign_change(x, false)
    end

    # Adjust to closest value
    inext = idx == lastindex(x) ? firstindex(x) : idx+1
    iprev = idx == firstindex(x) ? lastindex(x) : idx-1
    if abs(x[inext]) < abs(x[idx])
        idx = inext
    elseif abs(x[iprev]) < abs(x[idx])
        idx = iprev
    end

    return idx
end

function sign_change(x, sgn)
    if signbit(x[end]) == sgn
        # we consider peroidic boundary conditions
        start_idx = firstindex(x)
        xprev = x[end]
    elseif signbit(x[begin]) == sgn
        # we start on the correct sign
        start_idx = firstindex(x) + 1
        xprev = x[begin]
    else
        start_idx = firstindex(x)
        while signbit(x[start_idx]) ≠ sgn
            start_idx +=1
        end
        xprev = x[start_idx]
        start_idx += 1
    end
    sprev = signbit(xprev)
    @assert sprev == sgn
    idx = start_idx
    offset_x = OffsetArray(x[start_idx:end], start_idx:lastindex(x))
    for i in eachindex(offset_x)
        current_sign = signbit(x[i])
        if (current_sign ≠ sprev)
            idx = i
            break
        end
        xprev = x[i]
        sprev = current_sign
    end
    return idx
end

function integration_domain(x, y, quadrant, direction)
    if direction == :trigonometric
        plus = :+
        minus = :-
    else
        plus = :-
        minus = :+
    end

    if quadrant == 1
        a_idx = sign_change(y, minus => plus)
        b_idx = sign_change(x, plus => minus)
    elseif quadrant == 2
        a_idx = sign_change(x, plus => minus)
        b_idx = sign_change(y, plus => minus)
    elseif quadrant == 3
        a_idx = sign_change(y, plus => minus)
        b_idx = sign_change(x, minus => plus)
    elseif quadrant == 4
        a_idx = sign_change(x, minus => plus)
        b_idx = sign_change(y, minus => plus)
    else
        @error "Unkown quadrant $quadrant"
        a_idx = 0
        b_idx = 0
    end

    return direction == :trigonometric ? (a_idx, b_idx) : (b_idx, a_idx)
end

function discharge_area(df, quadrant, fixed_ΔV)
    I, V = df[!, Symbol("Current (mA)")], df[!, Symbol("Potential (V)")]
    t = df[!, Symbol("Time (s)")]

    a_idx, b_idx = integration_domain(V, I, quadrant, :orar)
    @assert a_idx < b_idx

    I, V = I[a_idx:b_idx], V[a_idx:b_idx]
    # account for integrating "in reverse"
    sgn = V[begin] > V[end] ? -1 : 1
    ∫IdV = sgn * integrate(V, I) * u"V*A"
    Δt = -sgn*(t[b_idx] - t[a_idx]) * u"s"
    ΔV = !isnothing(fixed_ΔV) ? sgn*fixed_ΔV : (V[end] - V[begin]) * u"V"

    return Δt, ΔV, ∫IdV
end
