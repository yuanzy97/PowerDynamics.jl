"""
```Julia
LineFailure(;from,to)
```
The arguments `from` and `to` specify the line that should be disconnected from the grid.
"""
struct LineFailure
    from
    to
end

struct LineFailure_new
    line_name
end

function (lf::LineFailure)(powergrid)
    @assert lf.from < lf.to "order important to remove the line from powergrid"
    filtered_lines = filter(l -> (l.from !=lf.from || l.to !=lf.to), copy(powergrid.lines))
    PowerGrid(powergrid.nodes, filtered_lines)
end

function filter_lines(lines::OrderedDict,line_name)
    OrderedDict(k=>v for (k,v) in lines if k!=line_name)
end

function filter_lines(lines::Array,line_name)
    copy(lines[1:end .!= line_name])
end

function (lf::LineFailure_new)(powergrid)
    filtered_lines=filter_lines(powergrid.lines,lf.line_name)
    PowerGrid(powergrid.nodes, filtered_lines)
end


"""
```Julia
simulate(lf::LineFailure, powergrid, x0; timespan)
```
Simulates a [`LineFailure`](@ref)
"""
function simulate(lf::LineFailure, powergrid, x0; timespan)
    solve(lf(powergrid), x0, timespan);
end

function simulate(lf::LineFailure_new, powergrid, x0, timespan)
    solve(lf(powergrid), x0, timespan);
end

const iipfunc = true # is in-place function


#LineFailure(;from,to) = LineFailure(from,to)


export LineFailure
export LineFailure_new