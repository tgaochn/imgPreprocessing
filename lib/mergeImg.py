# !/usr/bin/env python
# coding: utf-8
"""
mergeImg.py
Author:
    Tian Gao (tgaochn@gmail.com)
CreationDate:
    2018-6-6 15:23:47
Link:
    
Description:
    
"""
import sys
import os
import shutil


def copyCont(sourceFolder, targetFolder):
    for localFn in os.listdir(sourceFolder):
        fnPath = os.path.join(sourceFolder, localFn)
        shutil.copy2(fnPath, targetFolder)
# end_func


def mergeImg():
    argvLen = len(sys.argv)
    if argvLen < 3:
        print 'incorrect argument.'
        return
        
    inputPath = sys.argv[1]
    isForceMerge = eval(sys.argv[2])
    cameraFolderLis = os.listdir(inputPath)
    targetFolder = os.path.join(inputPath, 'merge')

    if os.path.exists(targetFolder):
        print "merge folder already exists!"
        return

    if isForceMerge:
        os.makedirs(targetFolder)
        for cameraId in cameraFolderLis:
            curFolder = os.path.join(inputPath, cameraId)
            copyCont(curFolder, targetFolder)
    else:
        if 'camera1' in cameraFolderLis and 'camera2' in cameraFolderLis:
            os.makedirs(targetFolder)
            cam1Folder = os.path.join(inputPath, 'camera1')
            cam2Folder = os.path.join(inputPath, 'camera2')
            copyCont(cam1Folder, targetFolder)
            copyCont(cam2Folder, targetFolder)
# end_func


def main():
    mergeImg()
# end_main


if __name__ == "__main__":
    main()
# end_if
