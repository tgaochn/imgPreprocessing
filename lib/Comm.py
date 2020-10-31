# coding:utf8

"""
Author          :   Tian Gao
CreationDate    :   2016-10-14 10:52:02
Description     :
"""

import datetime
import pickle
import os
import bitarray
import logging

INFO = logging.getLogger('root').info


def saveSingleDict(curDict, filenm):
    with open(filenm, 'w') as curFile:
        pickle.dump(curDict, curFile)
# end_def


def loadSingleDict(filenm):
    with open(filenm) as curFile:
        curDict = pickle.load(curFile)
    return curDict
# end_def


def print0(isLogging=False):
    if not isLogging:
        print '=' * 40
    else:
        INFO('=' * 40)
# end_func


def print9(isLogging=False):
    if not isLogging:
        print '==' * 40
    else:
        INFO('==' * 40)
# end_func


def printTime():
    now = str(datetime.datetime.now())
    print now[:19]
# end_func


def printWithTime(obj, isLogging=False):
    if not isLogging:
        now = str(datetime.datetime.now())
        print "%s - %s" % (now[:19], obj)
    else:
        INFO(obj)
# end_func


def showDict(curDict, isLogging=False):
    if not isLogging:
        for ker, value in curDict.iteritems():
            print "%s : %s" % (ker, value)
    else:
        for ker, value in curDict.iteritems():
            INFO("%s : %s" % (ker, value))
# end_func


def showList(curLis, isLogging=False):
    if not isLogging:
        for item in curLis:
            print item
    else:
        for item in curLis:
            INFO(item)
# end_func


def showMatrix(dataMatrix):
    for dataLis in dataMatrix:
        dataStr = '\t'.join(map(lambda x: str(x), dataLis))
        print dataStr
# end_func
