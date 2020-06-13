export @makesimpleerror

macro makesimpleerror(T, B, name)
    esc(quote
        export $T
        
        struct $T <: $B
            msg::String
        end
        $T() = $T("")
        
        function Base.show(io::IO, err::$T)
            write(io, $name)
            if !isempty(err.msg)
                write(io, ": ")
                write(io, err.msg)
            end
        end
    end)
end

@makesimpleerror FormatError Exception "Format error"
