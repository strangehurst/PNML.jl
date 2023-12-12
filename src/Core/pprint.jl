pprint(@nospecialize(x); kw...) =   pprint(stdout,   x; kw...)
pprintln(@nospecialize(x); kw...) = pprintln(stdout, x; kw...)

function pprintln(io::IO, @nospecialize(x); kw...)
    print(io, x; kw...)
    println(io)
end

function pprint(io::IO, @nospecialize(x); kw...)
    print(io, x; kw...)
end
