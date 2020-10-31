# -*- coding: utf-8 -*-
"""
ProjectName:

Author:
    Tian Gao
Email:
    tgaochn@gmail.com
CreationDate:
    5/18/2018
Description:
    1. Merge image files from different folder in camera and rename them.
    2. Create a folder for each plant given labels and format the folder structure.

    CAMERA_FOLDER should end with 'DCIM'

    input folder structure:
        ../cardId/DCIM/101DSC/.jpg
    output folder structure:
        ../camera1/date/plantId/camera1/.jpg
        ../camera2/date/plantId/camera2/.jpg

    process:
        1. copy the DCIM to the card1/card2 folder
        2. run the script on Linux
"""
import PIL.Image
import PIL.ExifTags
from lib import Comm
from utils.utils import getConfDict
import datetime
import time
import os
import shutil

CONF_FN = r'conf/rawImgFormatter.ini'
confDic = getConfDict(CONF_FN)

TARGET_FOLDER = confDic['cameraImg']['outputFolder']
ALL_IMG_INFO_LIS = [
    (confDic['cameraImg']['camera1_DCIM_folder'], 'camera1'),
    (confDic['cameraImg']['camera2_DCIM_folder'], 'camera2'),
]
HAS_LABEL = eval(confDic['cameraImg']['hasLabel'])
IMG_SET_CAP = eval(confDic['cameraImg']['ImgCntPerSet'])
FOLDER_NM_LIS = [  # remember enable "hasLabel"
    '1-1',
    '1-2_1',
    '1-2_final',
    '1-3',
    '2-1',
    '2-2',
    '2-3',
    '4-3', 
    '3-1',
    '3-2',
    '3-3',
    '4-2',
]


def formatImgFolder(imgPath, cameraId):
    print 'formatting image folders in path: %s, for camera: %s' % (imgPath, cameraId)
    print 'hasLabel: %s' % HAS_LABEL

    curDate = ''
    localImgFnLis = os.listdir(imgPath)

    if len(localImgFnLis) % IMG_SET_CAP != 0:
        print 'The number of images is not correct!'
        print 'It should be a multiple of IMG_SET_CAP'
        return '', ''

    # check number of images or mark as unlabeled
    labelCnt = len(localImgFnLis) / IMG_SET_CAP
    folderNmLis = FOLDER_NM_LIS

    # if no labels, a2 should be ran to generate label from QR code
    if not HAS_LABEL:
        if folderNmLis:
            print 'Please keep the FOLDER_NM_LIS empty!'
            return '', ''
        folderNmLis = map(lambda x: 'unlabeled_%s' % x, range(labelCnt))
    else:
        if len(localImgFnLis) != len(folderNmLis) * IMG_SET_CAP:
            print 'The number of images is not correct!'
            print 'files cnt: %s, should have: %s' % (
                len(localImgFnLis), len(folderNmLis) * IMG_SET_CAP)
            return '', ''

    # get datetime of the images from EXIF
    imgInfoLis = []
    for localImgFn in localImgFnLis:
        if not localImgFn.endswith('.jpg') and not localImgFn.endswith('.JPG'):
            continue
        imgFn = os.path.join(imgPath, localImgFn)
        img = PIL.Image.open(imgFn)
        exif = {
            PIL.ExifTags.TAGS[k]: v
            for k, v in img._getexif().iteritems()
            if k in PIL.ExifTags.TAGS
        }
        imgInfoLis.append((imgFn, exif['DateTime']))
        if not curDate:
            curDate = exif['DateTime'][:10].replace(':', '-')
    imgInfoLis.sort(key=lambda x: x[1])

    # organize folder tree
    for imgId, (imgFn, _) in enumerate(imgInfoLis):
        folderId = imgId / IMG_SET_CAP
        plantId = folderNmLis[folderId]
        targetFolderNm = os.path.join(
            TARGET_FOLDER, cameraId, curDate, plantId, cameraId)
        if not os.path.exists(targetFolderNm):
            os.makedirs(targetFolderNm)
        try:
            # the last file will raise an error
            shutil.move(imgFn, targetFolderNm)
        except:
            pass

    # delete the redundant .JPG file
    localFnLis = os.listdir(imgPath)
    if len(localFnLis) == 1:
        for localFn in os.listdir(imgPath):
            if os.path.splitext(localFn)[1] == '.JPG':
                fn = os.path.join(imgPath, localFn)
                return imgPath, fn

    return '', ''
# end_func


def mergeCameraFolder(imgPath):
    # merge the sub folder in DCIM folder
    print 'merging subfolders in path: %s' % imgPath
    oldFolderSet = set()

    localFolderLis = os.listdir(imgPath)
    for localFolder in localFolderLis:
        folderPath = os.path.join(imgPath, localFolder)
        oldFolderSet.add(folderPath)
        localImgLis = os.listdir(folderPath)
        for localImgFn in localImgLis:
            srcImgFn = os.path.join(folderPath, localImgFn)
            baseNm, extNm = os.path.splitext(localImgFn)
            newLocalNm = '%s_%s%s' % (baseNm, localFolder[:3], extNm)
            destImgFn = os.path.join(imgPath, newLocalNm)
            shutil.move(srcImgFn, destImgFn)

    for oldFolder in oldFolderSet:
        try:
            os.removedirs(oldFolder)
        except:
            pass

    return
# end_func


def main():
    for imgPath, cameraId in ALL_IMG_INFO_LIS:
        if imgPath[-4:] != 'DCIM':
            print 'path name is not correct, please check it!'
            return
        if int(imgPath[-6]) % 2 != int(cameraId[-1]) % 2:
            print 'CameraID might be not correct, please check it again!'
            return

        mergeCameraFolder(imgPath)
        imgPath, fn = formatImgFolder(imgPath, cameraId)
        if fn:
            os.remove(fn)
            os.rmdir(imgPath)
# end_main


if __name__ == "__main__":
    main()
# end_if
