
using CRC
using Compat
using Base.Test
import Libz.crc32


function test_crc(spec)
    print(spec)
    for tables in (NoTables, Single, Multiple)
        result = crc(spec, tables=tables)(CHECK)
        if result != spec.check
            println("$tables $(hex(result))")
            @test result == spec.check
        end
        print(".")
    end
    println("ok")
end

function test_all()
    print("all")
    bad = Set()
    for _ in 1:10
        data = rand(UInt8, rand(100:200))
        for (name, spec) in ALL
            if ! in(spec, bad)
                r1 = crc(spec, tables=NoTables)(data)
                for tables in (Single, Multiple)
                    r2 = crc(spec, tables=tables)(data)
                    if r1 != r2
                        push!(bad, spec)
                    end
                end
                print(".")
            end
        end
    end
    if length(bad) > 0
        println("failed:")
        for spec in bad
            println(spec)
        end
        @test false
    else
        println("ok")
    end
end

function test_string()
    crc32 = crc(CRC_32)
    @test crc32("abcxyz") == 0xacc462e9
end

function tests()
    test_string()
    test_crc(CRC_3_ROHC)
    test_crc(CRC_4_ITU)
    test_crc(CRC_7_ROHC)
    test_crc(CRC_32)
    test_crc(CRC_7)
    test_crc(CRC_8)
    test_crc(CRC_10)
    test_all()
end

tests()

#SIZE = 300_000_000
SIZE = 300_000

function time_libz()
    println("libz")
    data = rand(UInt8, SIZE)
    check = crc32(data)
    @time crc32(data)
    for tables in (Single, Multiple)
        ours = crc(CRC_32, tables=tables)
        @assert ours(data) == check
        println(tables)
        @time ours(data)
    end
end

function time_no_tables()
    println("no_tables")
    ours = crc(CRC_15, tables=NoTables)
    data = rand(UInt8, round(Int, SIZE//10))
    @assert ours(CHECK) == CRC_15.check
    @time ours(data)
end

function time_padded()
    println("padded")
    ours = crc(CRC_64)
    data = rand(UInt8, SIZE)
    @assert ours(CHECK) == CRC_64.check
    @time ours(data)
end

srand(0)  # repeatable results

time_libz()
time_no_tables()
time_padded()
