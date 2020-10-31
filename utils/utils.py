#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
ProjectName:

Author:
    Tian Gao
Email:
    tgaochn@gmail.com
CreationDate:
    5/12/2018
Description:

"""
def getConfDict(confFn):
    import ConfigParser
    class myconf(ConfigParser.ConfigParser):
        def __init__(self, defaults=None):
            ConfigParser.ConfigParser.__init__(self, defaults=None)
        #end_func

        def optionxform(self, optionstr):
            return optionstr
        #end_func
    #end_class

    cf = myconf()
    cf.read(confFn)
    sections = cf.sections()
    confDic = {section: dict(cf.items(section)) for section in sections}
    return confDic
#end_func

def func():
    # test conf reader
    confFn = 'conf/proj.ini'
    confDic = getConfDict(confFn)
    print confDic
# end_func

def main():
    func()
#end_main

if __name__ == "__main__":
    main()
#end_if
