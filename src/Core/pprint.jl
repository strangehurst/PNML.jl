pprint(@nospecialize(x); kw...) =   pprint(stdout,   x; kw...)
pprintln(@nospecialize(x); kw...) = pprintln(stdout, x; kw...)

#pprint(io::IO, x; kw...) =   pprint(io,   MIME"text/plain"(), x; kw...)
#pprintln(io::IO, x; kw...) = pprintln(io, MIME"text/plain"(), x; kw...)

function pprintln(io::IO, @nospecialize(x); kw...)
#function pprintln(io::IO, m::MIME, @nospecialize(x); kw...)
    print(io, x; kw...)
    println(io)
end

function pprint(io::IO, @nospecialize(x); kw...)
    #function pprint(io::IO, m::MIME, @nospecialize(x); kw...)
    print(io, x; kw...)
end
