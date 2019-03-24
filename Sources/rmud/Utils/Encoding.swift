import CIconv
#if os(Linux)
import Glibc
#endif

enum Charset {
    case utf8
    case koi8r
    case cp1251
    case cp866
}

class Encoding {
    static func convert(fromCharset: Charset, toCharset: Charset, data inbuf: [CChar]) -> [CChar]? {
        let fromCharsetString = charsetToString(fromCharset)
        let toCharsetString = charsetToString(toCharset)
        
        let cd = iconv_open(toCharsetString, fromCharsetString)
        if cd == iconv_t(bitPattern: -1) {
            return nil
        }
        
        var inbuf = inbuf
        var inleft = inbuf.count

        // We'll start off allocating an output buffer which is the same size
        // as our input buffer.
        //outlen = inleft;
        // Can't grow buffer in steps due to a bug in some libiconv versions.
        // To workaround the bug, conversion has to be started from beginning
        // on overflow.
        // So, allocate buffer big enough to avoid any reallocations at all.
        var outlen = max(1024, inbuf.count * 4)
        
        // We allocate 4 bytes more than what we need for nul-termination...
        // UPD: we don't need null termination
        var output = [CChar](repeating: 0, count: outlen /* + 4 */)
        
        var outleft: Int

        repeat {
            errno = 0
            outleft = outlen
            var retval: Int = -1
            inbuf.withUnsafeMutableBufferPointer { inbufPtr in
                output.withUnsafeMutableBufferPointer { outputPtr in
                    var outbufAddress = outputPtr.baseAddress

                    var inbufAddress = inbufPtr.baseAddress
                    retval = iconv(cd, &inbufAddress, &inleft, &outbufAddress, &outleft)
                }
            }
            if retval != -1 { // Success
                break
            }
            
            // Error:
            if errno == EINVAL {
                // EINVAL  An  incomplete  multibyte sequence has been encountered in the input.
                // We'll just truncate it and ignore it.
                break
            }
    
            if errno != E2BIG {
                // EILSEQ An invalid multibyte sequence has been  encountered
                //        in the input.
                // Bad input, we can't really recover from this.
                iconv_close(cd)
                return []
            }
            
            //E2BIG   There is not sufficient room at *outbuf.
            //We just need to grow our outbuffer and try again.
            //   converted = outbuf - &output[0];
            //   outlen += inleft * 2 + 8;
            //   output.resize(outlen + 4);

            // https://sourceware.org/bugzilla/show_bug.cgi?id=9793
            // Bug workaround:
            outlen += max(1024, inbuf.count * 4)
            output = [CChar](repeating: 0, count: outlen + 4)
            //logf("output.size=%d", (int)output.size());
            inleft = inbuf.count
        } while true
        
        // Flush the iconv conversion
        output.withUnsafeMutableBufferPointer { outputPtr in
            let bytesWritten = outlen - outleft
            var outbufAddress = outputPtr.baseAddress?.advanced(by: bytesWritten)

            iconv(cd, nil, nil, &outbufAddress, &outleft)
            iconv_close(cd)
        
            // Note: not all charsets can be nul-terminated with a single
            // nul byte. UCS2, for example, needs 2 nul bytes and UCS4
            // needs 4. I hope that 4 nul bytes is enough to terminate all
            // multibyte charsets?
            
            // nul-terminate the string
            //memset(outbufAddress, 0, 4)
        }
        
        let bytesWritten = outlen - outleft
        return Array(output.prefix(upTo: bytesWritten))
    }
    
    static func charsetToString(_ charset: Charset) -> String {
        switch charset {
        case .utf8: return "UTF-8//IGNORE"
        case .koi8r: return "KOI8-R"
        case .cp1251: return "CP1251"
        case .cp866: return "CP866"
        }
    }
}
