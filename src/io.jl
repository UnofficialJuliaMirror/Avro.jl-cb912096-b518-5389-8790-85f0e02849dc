module Io

import Base.write

using Avro.Schemas

export Encoder,
       Decoder,
       BinaryEncoder,
       BinaryDecoder,
       DatumWriter,
       DatumReader,
       encode,
       write

abstract Encoder
abstract Decoder

"""
Writes binary data of builtin and primtive types to an output stream.
"""
immutable BinaryEncoder <: Encoder
    stream::IO
end

"""
Reads data of simple and primitive types from an input stream.
"""
immutable BinaryDecoder <: Decoder
    stream::IO
end

"""
Writes binary data of user-defined types to an output stream. The user-defined
type is expected to adhere to a schema.
"""
immutable DatumWriter
    encoder::Encoder
    schema::Schema
end

"""
Reads binary data of user-defined types from an input stream. The user-defined
type is expected to adhere to a schema.
"""
immutable DatumReader
    decoder::Decoder
    schema::Schema
end

encode(encoder::BinaryEncoder, value::Void) = 0
encode(encoder::BinaryEncoder, value::Bool) = write(encoder.stream, value)

function encode(encoder::BinaryEncoder, value::Int32)
    stream = encoder.stream
    bytes_written = 0
    n = (value << 1) $ (value >> 31)
    if n > 0x7F
        bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
        n >>>= 7
        if n > 0x7F
            bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
            n >>>= 7
            if n > 0x7F
                bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                n >>>= 7
                if n > 0x7F
                    bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                    n >>>= 7
                end
            end
        end
    end
    bytes_written += write(stream, n % UInt8)
    bytes_written
end

function encode(encoder::BinaryEncoder, value::Int64)
    stream = encoder.stream
    bytes_written = 0
    n = (value << 1) $ (value >> 63)
    if n > 0x7F
        bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
        n >>>= 7
        if n > 0x7F
            bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
            n >>>= 7
            if n > 0x7F
                bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                n >>>= 7
                if n > 0x7F
                    bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                    n >>>= 7
                    if n > 0x7F
                        bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                        n >>>= 7
                        if n > 0x7F
                            bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                            n >>>= 7
                            if n > 0x7F
                                bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                                n >>>= 7
                                if n > 0x7F
                                    bytes_written += write(stream, ((n | 0x80) & 0xFF) % UInt8)
                                    n >>>= 7
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    bytes_written += write(stream, n % UInt8)
    bytes_written
end

encode(encoder::BinaryEncoder, value::Float32) = write(encoder.stream, value)
encode(encoder::BinaryEncoder, value::Float64) = write(encoder.stream, value)
encode(encoder::BinaryEncoder, value::UInt8) = write(encoder.stream, value)
encode(encoder::BinaryEncoder, value::Vector{UInt8}) = write(encoder.stream, value)

function encode(encoder::BinaryEncoder, value::String)
    encode(encoder, sizeof(value)) + write(encoder.stream, value)
end

# Default writers

write(encoder::Encoder, schema::NullSchema, value::Void) = encode(encoder, value)
write(encoder::Encoder, schema::BooleanSchema, value::Bool) = encode(encoder, value)
write(encoder::Encoder, schema::IntSchema, value::Int32) = encode(encoder, value)
write(encoder::Encoder, schema::LongSchema, value::Int64) = encode(encoder, value)
write(encoder::Encoder, schema::FloatSchema, value::Float32) = encode(encoder, value)
write(encoder::Encoder, schema::DoubleSchema, value::Float64) = encode(encoder, value)
write(encoder::Encoder, schema::BytesSchema, value::UInt8) = encode(encoder, value)
write(encoder::Encoder, schema::BytesSchema, value::Vector{UInt8}) = encode(encoder, value)
write(encoder::Encoder, schema::StringSchema, value::String) = encode(encoder, value)

function write{T}(encoder::Encoder, schema::ArraySchema, value::Vector{T})
    bytes_written = encode(encoder, Int64(length(value)))
    for item in value
        bytes_written += write(encoder, schema.items, item)
    end
    bytes_written += encode(encoder, zero(UInt8))
    bytes_written
end

function write{T}(encoder::Encoder, schema::MapSchema, value::Dict{String, T})
    bytes_written = encode(encoder, Int64(length(value)))
    for (k, v) in value
        bytes_written += encode(encoder, Schemas.string, k)
        bytes_written += write(encoder, schema.values, v)
    end
    bytes_written += encode(encoder, zero(UInt8))
    bytes_written
end

write(writer::DatumWriter, value) = write(writer.encoder, writer.schema, value)

end
