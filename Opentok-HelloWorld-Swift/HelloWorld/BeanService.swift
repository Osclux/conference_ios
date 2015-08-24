//
//  BeanService.swift
//  Plattan
//
//  Created by Oscar Lantz on 2015-08-24.
//  Copyright (c) 2015 Oscar Lantz. All rights reserved.
//

import Foundation
import Bean_iOS_OSX_SDK


class BeanService {
    
    var beanManager : PTDBeanManager?
    
    init() {
        self.beanManager = PTBeanManager(delegate: self)
    }
}