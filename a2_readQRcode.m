% readQRcode.m
% @Author : Tian Gao (tgaochn@gmail.com)
% @Link   : 
% @Date   : 2018-7-5 13:25:34
% input folder structure:
%    ../camera1/date/unlabeledPlantId/camera1/.jpg
%    ../camera2/date/unlabeledPlantId/camera2/.jpg
% output folder structure:
%    ../cameraId/date/labeledPlantId/cameraId/.jpg


clc; clear; close all; warning off all;
addpath('utils/')
logFn = 'log.log';
logger = log4m.getLogger(logFn);
confFn = 'conf/rawImgFormatter.ini';
ini = IniConfig();
ini.ReadFile(confFn);
cropReg1 = eval(ini.GetValues('qrcodeReader', 'cropReg1'));
cropReg2 = eval(ini.GetValues('qrcodeReader', 'cropReg2'));
cropReg3 = eval(ini.GetValues('qrcodeReader', 'cropReg3'));
cropReg4 = eval(ini.GetValues('qrcodeReader', 'cropReg4'));
cropReg5 = eval(ini.GetValues('qrcodeReader', 'cropReg5'));
cropReg6 = eval(ini.GetValues('qrcodeReader', 'cropReg6'));
cropReg7 = eval(ini.GetValues('qrcodeReader', 'cropReg7'));
cropReg8 = eval(ini.GetValues('qrcodeReader', 'cropReg8'));
cropReg9 = eval(ini.GetValues('qrcodeReader', 'cropReg9'));
cropReg10 = eval(ini.GetValues('qrcodeReader', 'cropReg10'));
cropReg11 = eval(ini.GetValues('qrcodeReader', 'cropReg11'));
cropReg12 = eval(ini.GetValues('qrcodeReader', 'cropReg12'));
cropReg13 = eval(ini.GetValues('qrcodeReader', 'cropReg13'));
cropReg = {cropReg1, cropReg2, cropReg3, cropReg4, cropReg5, cropReg6, cropReg7, cropReg8, cropReg9, cropReg10, cropReg11, cropReg12, cropReg13};
dataPath = ini.GetValues('cameraImg', 'outputFolder');
enabledAllDate = eval(ini.GetValues('qrcodeReader', 'enableAllDate'));
enabledDate = ini.GetValues('qrcodeReader', 'enabledDate');
randFnRange = ini.GetValues('qrcodeReader', 'randFnRange');

tmpDir = dir(dataPath);
for n = 1: length(tmpDir)
    cardID = tmpDir(n).name;
    if(isequal(cardID, '.' ) || isequal(cardID, '..') || ~tmpDir(n).isdir)
        continue
    end

    cardPath = [dataPath, '/', cardID];
    cardDir = dir(cardPath);

    for i = 1:length(cardDir) % ./date
        imgDate = cardDir(i).name;
        if(isequal(imgDate, '.' ) || isequal(imgDate, '..') || ~cardDir(i).isdir)
            continue
        end

        if(~enabledAllDate && ~contains(enabledDate, imgDate))
            continue
        end

        plantIdPath = [cardPath, '/', imgDate];
        plantIdDir = dir(plantIdPath);
        logger.info(['-----running on date: ', imgDate, '-----']);
        
        parfor j = 1:length(plantIdDir)% ./date/plantId
            % generate a random int as the filenm of cropped img
            randomInt = randi(randFnRange);
            croppedImFn = ['tmp/', int2str(randomInt), '.png'];
            while(exist(croppedImFn, 'file'))
                randomInt = randi(randFnRange);
                croppedImFn = ['tmp/', int2str(randomInt), '.png'];
            end

            hasQRcode = false;
            label = '';
            plantId = plantIdDir(j).name;
            
            if(isequal(plantId, '.' ) || isequal(plantId, '..') || ~plantIdDir(j).isdir)
                continue
            end

            cameraIdPath = [plantIdPath, '/', plantId];
            cameraIdDir = dir(cameraIdPath);
            
            for k = 1: length(cameraIdDir) % ./date/plantId/camera1
                cameraId = cameraIdDir(k).name;
                if(isequal(cameraId, '.' ) || isequal(cameraId, '..'))
                    continue
                end

                imgInputPath = [cameraIdPath, '/', cameraId];
                logger.info(['running on plantId:', plantId, ', cameraId:', cameraId]);

                imgDir = dir(imgInputPath);

                for l = 1: length(imgDir)
                    imgLocalFn = imgDir(l).name;

                    if(isequal(imgLocalFn, '.' ) || isequal(imgLocalFn, '..') || imgDir(l).isdir)
                        continue
                    end

                    imgFn = [imgInputPath, '/', imgLocalFn];
                    im = imread(imgFn);

                    % crop a certain region and scan it to decode qrcode
                    for m = 1 : length(cropReg)
                        croppedIm = imcrop(im, cropReg{m});
                        imwrite(croppedIm, croppedImFn);
                        cmd = ['./scan_image ', croppedImFn];
                        [status, info] = system(cmd);
                        regRlt = regexp(info,'\([^)]*)','match');
                        if ~isempty(regRlt)
                            hasQRcode = true;
                            label = regRlt{1}(2: end - 1);
                            break;
                        end
                    end

                    if hasQRcode
                        break
                    end
                end

                if hasQRcode
                    break
                else
                    logger.info(['fail to read qrcode in folder: ', imgInputPath]);
                end
            end
                
            % rename the plantId with labels
            if hasQRcode
                fromPath = cameraIdPath;
                toPath = [plantIdPath, '/', label];
                while exist(toPath, 'dir')
                    toPath = [toPath, '_']
                end
                cmd = ['mv ', fromPath, ' ', toPath]
                system(cmd)
            end

            delete(croppedImFn);
        end
    end
end