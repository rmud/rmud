//  Based on:
//
//  SocketUtils.swift
//  BlueSocket
//
//  Created by Bill Abt on 11/19/15.
//  Copyright © 2016 IBM. All rights reserved.
//
// 	Licensed under the Apache License, Version 2.0 (the "License");
// 	you may not use this file except in compliance with the License.
// 	You may obtain a copy of the License at
//
// 	http://www.apache.org/licenses/LICENSE-2.0
//
// 	Unless required by applicable law or agreed to in writing, software
// 	distributed under the License is distributed on an "AS IS" BASIS,
// 	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// 	See the License for the specific language governing permissions and
// 	limitations under the License.
//

import Foundation

#if os(Linux)

#if arch(arm)
	let __fd_set_count = 16
#else
	let __fd_set_count = 32
#endif

	extension fd_set {
	
		@inline(__always)
		mutating func withCArrayAccess<T>(block: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
			return try withUnsafeMutablePointer(to: &__fds_bits) {
				try block(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Int32.self))
			}
		}
	}

#else   // not Linux on ARM
	// __DARWIN_FD_SETSIZE is number of *bits*, so divide by number bits in each element to get element count
	// at present this is 1024 / 32 == 32
	let __fd_set_count = Int(__DARWIN_FD_SETSIZE) / 32

	extension fd_set {
	
		@inline(__always)
		mutating func withCArrayAccess<T>(block: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
			return try withUnsafeMutablePointer(to: &fds_bits) {
				try block(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Int32.self))
			}
		}
	}

#endif

public extension fd_set {
	
	@inline(__always)
	private static func address(for fd: Int32) -> (Int, Int32) {
		var intOffset = Int(fd) / __fd_set_count
		#if _endian(big)
		if intOffset % 2 == 0 {
			intOffset += 1
		} else {
			intOffset -= 1
		}
		#endif
		let bitOffset = Int(fd) % __fd_set_count
		let mask = Int32(bitPattern: UInt32(1 << bitOffset))
		return (intOffset, mask)
	}
	
	///
	/// Zero the fd_set
	///
    mutating func zero() {
		#if swift(>=4.1)
		withCArrayAccess { $0.initialize(repeating: 0, count: __fd_set_count) }
		#else
		withCArrayAccess { $0.initialize(to: 0, count: __fd_set_count) }
		#endif
	}
	
	///
	/// Set an fd in an fd_set
	///
	/// - Parameter fd:	The fd to add to the fd_set
	///
    mutating func set(_ fd: Int32) {
		let (index, mask) = fd_set.address(for: fd)
		withCArrayAccess { $0[index] |= mask }
	}
	
	///
	/// Clear an fd from an fd_set
	///
	/// - Parameter fd:	The fd to clear from the fd_set
	///
    mutating func clear(_ fd: Int32) {
		let (index, mask) = fd_set.address(for: fd)
		withCArrayAccess { $0[index] &= ~mask }
	}
	
	///
	/// Check if an fd is present in an fd_set
	///
	/// - Parameter fd:	The fd to check
	///
	///	- Returns:	True if present, false otherwise.
	///
    mutating func isSet(_ fd: Int32) -> Bool {
		let (index, mask) = fd_set.address(for: fd)
		return withCArrayAccess { $0[index] & mask != 0 }
	}
}

