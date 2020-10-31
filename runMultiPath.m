% process images from all the folders in the given path
% input folder should be ./group/date/plantId/camera1/.jpg

clc;clear;close all;

addpath('utils/')
addpath('lib/')
addpath('maskFunc/')

logger = log4m.getLoggerWithLV('logging.log', 0);
confFn = 'conf/prepareImg.ini';
ini = IniConfig();
ini.ReadFile(confFn);
inputPath = ini.GetValues('MultiPath', 'imgInputPath');
outputPath = ini.GetValues('MultiPath', 'imgOutputPath');
overwriteFlag = eval(ini.GetValues('global', 'overwrite'));
maskColorSpaceType = ini.GetValues('MaskFunc', 'colorSpace');
enableCrop = eval(ini.GetValues('imgCrop', 'enable'));
enableAllGroup = eval(ini.GetValues('group', 'enableAll'));
enabledGroup = ini.GetValues('group', 'enabledGroup');
enableAllDate = eval(ini.GetValues('imgDate', 'enableAll'));
enabledDate = ini.GetValues('imgDate', 'enabledDate');
enableAllPlant = eval(ini.GetValues('plantId', 'enableAll'));
enabledPlant = ini.GetValues('plantId', 'enabledPlant');
enableAllCamera = eval(ini.GetValues('cameraId', 'enableAll'));
enabledCamera = ini.GetValues('cameraId', 'enabledCamera');
enableBothSize = eval(ini.GetValues('ImgSize', 'enableBothSize'));
enableDownsize = eval(ini.GetValues('ImgSize', 'enableDownsize'));
resizeX = ini.GetValues('ImgSize', 'resizeX');
resizeY = ini.GetValues('ImgSize', 'resizeY');
enableDenoise = eval(ini.GetValues('Denoise', 'enable'));
densityThres = ini.GetValues('Denoise', 'densityThres');
minAreaThres = ini.GetValues('Denoise', 'minAreaThres');
debugImgFn = '';
debugMode = false;

logger.info('begin to preprocess images');
logger.info(['input: ', inputPath]);
logger.info(['output: ', outputPath]);
logger.info(['mask colorspace: ', maskColorSpaceType]);
logger.info(['overwrite old result:', num2str(double(overwriteFlag))])
logger.info(['enableAllGroup: ', num2str(double(enableAllGroup))]);
if ~enableAllGroup
    logger.info(['enabledGroup: ', enabledGroup]);
end
logger.info(['enableAllDate: ', num2str(double(enableAllDate))]);
if ~enableAllDate
    logger.info(['enabledDate: ', enabledDate]);
end
logger.info(['enableAllPlant: ', num2str(double(enableAllPlant))]);
if ~enableAllPlant
    logger.info(['enabledPlant: ', enabledPlant]);
end
logger.info(['enableAllCamera: ', num2str(double(enableAllCamera))]); 
if ~enabledCamera
    logger.info(['enabledCamera: ', enabledCamera]);
end
logger.info(['enableBothSize: ', num2str(double(enableBothSize))]);
if ~enableBothSize
    logger.info(['enableDownsize: ', num2str(double(enableDownsize))]);
end

groupDirLis = dir(inputPath);

for g = 1: length(groupDirLis)
    groupNm = groupDirLis(g).name;
    if(isequal(groupNm, '.' ) || isequal(groupNm, '..') || ~groupDirLis(g).isdir)
        continue
    end
        
    % check enabled group  
    if(~enableAllGroup &&~contains(enabledGroup, groupNm)) 
        continue
    end

    datePath = [inputPath, '/', groupNm];
    dateDir = dir(datePath);
    logger.info(['=====running on group: ', groupNm, '=====']);

    for i = 1:length(dateDir) % ./date
        imgDate = dateDir(i).name;
        if(isequal(imgDate, '.' ) || isequal(imgDate, '..') || ~dateDir(i).isdir)
            continue
        end
            
        % check enabled date
        % dateLabel = imgDate(1:10); % in case there are some extra strings in the folder name
        dateLabel = imgDate; % in case there are some extra strings in the folder name
        if(~enableAllDate &&~contains(enabledDate, dateLabel))
            continue
        end

        plantIdPath = [datePath, '/', imgDate];
        plantIdDir = dir(plantIdPath);
        logger.info(['-----running on date: ', dateLabel, '-----']);
        
        for j = 1:length(plantIdDir)% ./date/plantId
            plantId = plantIdDir(j).name;
            
            if(isequal(plantId, '.' ) || isequal(plantId, '..') || ~plantIdDir(j).isdir)
                continue
            end

            % check enabled plant ID
            if(~enableAllPlant && ~contains(enabledPlant, plantId))
                continue
            end

            cameraIdPath = [plantIdPath, '/', plantId];
            cameraIdDir = dir(cameraIdPath);

            logger.info(['running on plant id:', plantId]);
            
            sizeOutputPath = [outputPath, '/', groupNm,'/', imgDate, '/', plantId];
            sizeLis = {'resized', 'original'};
            if ~enableBothSize
                if enableDownsize
                    sizeLis = {'resized'};
                else
                    sizeLis = {'original'};
                end
            end

            for k = 1: length(cameraIdDir) % ./date/plantId/camera1
                cameraId = cameraIdDir(k).name;

                if(isequal(cameraId, '.' ) || isequal(cameraId, '..') || ~cameraIdDir(k).isdir)
                    continue
                end

                % check enabled camera ID
                if(~enableAllCamera &&~contains(enabledCamera, cameraId))
                    continue
                end

                % check enabled crop reg
                cameraKey = [dateLabel, '_', cameraId, '_removeRegLis'];
                if (ini.IsKeys('imgCrop', cameraKey))
                    removeRegLis = ini.GetValues('imgCrop', cameraKey);
                else
                    removeRegLis = '{}';
                end

                % check enabled mask key
                cameraKey = [dateLabel, '_', cameraId];
                confSecKeyLis = ["MaskThres_C1Min", "MaskThres_C1Max", "MaskThres_C2Min", "MaskThres_C2Max", "MaskThres_C3Min", "MaskThres_C3Max"];
                maskThresLis = [];
                for l = 1:length(confSecKeyLis)
                    confSecKey = [maskColorSpaceType, '_', confSecKeyLis(l)];
                    confSecKey = convertStringsToChars(join(confSecKey, ""));
                    if (ini.IsKeys(confSecKey, cameraKey))
                        maskThres = ini.GetValues(confSecKey, cameraKey);
                    else
                        maskThres = ini.GetValues(confSecKey, 'default');
                    end
                    maskThresLis(l) = maskThres;
                end
                imgInputPath = [cameraIdPath, '/', cameraId];

                for curSize = sizeLis % output: ./date/plantId/size/camera1
                    sizePath = [sizeOutputPath, '/', curSize{1}];
                    imgOutputPath = [sizeOutputPath, '/', curSize{1}, '/', cameraId];
                    if(exist(imgOutputPath, 'dir') && ~overwriteFlag)
                        logger.info(['current camera already exists, skip it. path: ', imgOutputPath]);
                        continue
                    end 

                    if(strcmpi(curSize{1}, "resized"))
                        enableDownsize = true;
                    else
                        enableDownsize = false;
                    end

                    logger.info(['input path: ', imgInputPath]);
                    logger.info(['output path: ', imgOutputPath]);
                    logger.info(['using mask threshold: ', mat2str(maskThresLis)]);
                    if enableCrop
                        logger.info(['using cropping region: ', string(removeRegLis)]);
                    end
                    logger.info('');
                    removeRegLis = eval(removeRegLis);

                    prepareImgSinglePath(imgInputPath, imgOutputPath, enableDownsize, resizeX, resizeY, maskColorSpaceType, maskThresLis, enableCrop, removeRegLis, enableDenoise, densityThres, minAreaThres, debugMode, debugImgFn)
                end
            end

            % meger img in different cameras
            logger.info(['merging img in path:', sizePath])
            for curSize = sizeLis
                sizePath = [sizeOutputPath, '/', curSize{1}];
                cmd = ['python lib/mergeImg.py ', sizePath, ' True']; % the last parameter means merge forcely
                [status, info] = system(cmd);
            end
        end
    end
end