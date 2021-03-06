//
//  MockURLProtocol.swift
//  OpenMarket
//
//  Created by 이영우 on 2021/05/21.
//

import Foundation
@testable import OpenMarket

class MockURLSession: URLProtocol {
  static var requestHandler: ((URLRequest) -> (HTTPURLResponse?, Data?, Error?))?
  
  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }
  
  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  override func startLoading() {
    guard let handler = MockURLSession.requestHandler else {
      fatalError()
    }
    
    let (response, data, error) = handler(request)
    
    if let error = error {
      client?.urlProtocol(self, didFailWithError: error)
    }
    
    if let response = response {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    
    if let data = data {
      client?.urlProtocol(self, didLoad: data)
    }
    
    client?.urlProtocolDidFinishLoading(self)
  }
  
  override func stopLoading() { }
}
