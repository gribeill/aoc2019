rndict = Dict(1 => 3, 2 => 3, 
              3 => 1, 4 => 1, 
              5 => 2, 6 => 2, 
              7 => 3, 8 => 3,
              9 => 1,
              99 => 0)

struct OpCode
    instr::Int
    mode::Array{Int, 1}
    N::Int
end

function OpCode(c::Int)
    digs = digits(c)
    oc = digs[1] + (length(digs) > 1 ? 10*digs[2] : 0)
    N = rndict[oc]
    mode = zeros(Int, N)
    mode[1:length(digs[3:end])] = digs[3:end]
    return OpCode(oc, mode, N)
end 


function intcode_computer(program::Array{Int,1}, input::Channel{Int}, output::Channel{Union{Int, Symbol}}; pc::Int=1)
    
    Np = length(program)
    Np_new = 10*Np
    for j=1:(Np_new-Np)
        push!(program, 0)
    end
    
    jump_flag = false
    rel_base = 0
    
    function load(addr::Int, mode::Int)::Int
        #println("Load: $(addr) -- $(mode)")
        if mode == 0
            return program[addr+1]
        elseif mode == 1
            return addr
        elseif mode == 2
            return program[addr + rel_base + 1]
        else
            error("Unknown mode $(mode).")
        end
    end
    
    function store(data::Int, addr::Int, mode::Int)
        #println("Store: $(data) --> $(addr) -- $(mode)")
        if mode == 0
            program[addr+1] = data
        elseif mode == 1
            error("Invalid mode 1 for store instruction.")
        elseif mode == 2
            program[addr + rel_base + 1] = data
        else
            error("Unknown mode $(mode).")
        end
    end
    
    function load_input(dst::Int, mode::Int)
        #println("Waiting for next input: store to $(dst) -- $(mode)")
        inp = take!(input)
        store(inp, dst, mode)
    end
    
    function store_output(data::Int)
        #println("Tried to store output $(data)")
        put!(output, data)    
    end    
    
    function jtrue(x::Int, y::Int)
        if x != 0 
            pc = y+1
            jump_flag = true
        end
    end
    
    function jfalse(x::Int, y::Int)
        if x == 0  
            pc = y+1 
            jump_flag = true
        end
    end
    
    lt(x::Int, y::Int)::Int = Int(x < y)
    
    eq(x::Int, y::Int)::Int = Int(x == y)
    
    while program[pc] != 99
        jump_flag = false
        oc = OpCode(program[pc])     
        #println(oc)
        if oc.instr == 1
            x = load(program[pc+1], oc.mode[1])
            y = load(program[pc+2], oc.mode[2])
            store(x+y, program[pc+3], oc.mode[3])
            
        elseif oc.instr == 2
            x = load(program[pc+1], oc.mode[1])
            y = load(program[pc+2], oc.mode[2])
            store(x*y, program[pc+3], oc.mode[3])
            
        elseif oc.instr == 3
            load_input(program[pc+1], oc.mode[1])
            
        elseif oc.instr == 4
            x = load(program[pc+1], oc.mode[1])
            store_output(x)
            
        elseif oc.instr == 5
            x = load(program[pc+1], oc.mode[1])
            y = load(program[pc+2], oc.mode[2])
            jtrue(x, y)
        elseif oc.instr == 6
            x = load(program[pc+1], oc.mode[1])
            y = load(program[pc+2], oc.mode[2])
            jfalse(x, y)
            
        elseif oc.instr == 7
            x = load(program[pc+1], oc.mode[1])
            y = load(program[pc+2], oc.mode[2])
            store(lt(x,y), program[pc+3], oc.mode[3])
            
        elseif oc.instr == 8
            x = load(program[pc+1], oc.mode[1])
            y = load(program[pc+2], oc.mode[2])
            store(eq(x,y), program[pc+3], oc.mode[3])
            
        elseif oc.instr == 9
            rel_base += load(program[pc+1], oc.mode[1])
            
        
        else
            @error "Something went wrong! Got code $(oc.instr)."
        end
        
        pc += (jump_flag ? 0 : oc.N+1)
    end
    println("Computer finished!")
    put!(output, :done);
end