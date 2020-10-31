function prepareImgSinglePath(imgInputPath, imgOutputPath, enableDownsize, resizeX, resizeY, maskColorSpaceType, maskThresLis, enableCrop, removeRegLis, enableDenoise, densityThres, minAreaThres, debugMode, debugImgFn)
    imgInputDir  = [dir([imgInputPath, '/*.jpg']), dir([imgInputPath, '/*.JPG'])];
    if ~exist(imgOutputPath)
        mkdir(imgOutputPath)
    end

    if debugMode
        loopCnt = 1;
    else
        loopCnt = length(imgInputDir);
    end

    parfor i = 1: loopCnt
    % for i = 1: loopCnt
        % load image
        imgInputFn = [imgInputPath, '/', imgInputDir(i).name];
        imgInput = imread(imgInputFn);

        % resize the raw image
        if enableDownsize
            imgResized = imresize(imgInput, [resizeY, NaN]);
        else
            imgResized = imgInput;
        end

        % mask the image
        if maskColorSpaceType == 'LAB'
            colorSpace = rgb2lab(imgResized)
        else
            colorSpace = rgb2hsv(imgResized)
        end
        [BW, maskedImg] = maskUniv(imgResized, colorSpace, maskThresLis);

        if enableDenoise
            % density filter
            densIm = sum(maskedImg, 3);
            densIm(densIm < densityThres) = 0;

            % fill holes
            filledIm = imfill(densIm);

            % denoise
            BW = bwareaopen(filledIm, minAreaThres, 8);

            % generate final image after denosing
            channelR = maskedImg(:, :, 1);
            channelG = maskedImg(:, :, 2);
            channelB = maskedImg(:, :, 3);
            channelR(BW == 0) = 0;
            channelG(BW == 0) = 0;
            channelB(BW == 0) = 0;
            finalImg = zeros(size(maskedImg));
            finalImg(:, :, 1) = channelR;
            finalImg(:, :, 2) = channelG;
            finalImg(:, :, 3) = channelB;
            finalImg = uint8(finalImg);
        else
            finalImg = maskedImg;
        end

        % crop img, loop is not allowed in parfor
        if enableCrop
            regCnt = length(removeRegLis);
            if regCnt >= 1
                removeReg = removeRegLis{1};
                removeReg = uint16(removeReg);
                finalImg(removeReg(2):removeReg(2) + removeReg(4), removeReg(1):removeReg(1) + removeReg(3), :) = 0;
            end
            if regCnt >= 2
                removeReg = removeRegLis{2};
                removeReg = uint16(removeReg);
                finalImg(removeReg(2):removeReg(2) + removeReg(4), removeReg(1):removeReg(1) + removeReg(3), :) = 0;
            end
            if regCnt >= 3
                removeReg = removeRegLis{3};
                removeReg = uint16(removeReg);
                finalImg(removeReg(2):removeReg(2) + removeReg(4), removeReg(1):removeReg(1) + removeReg(3), :) = 0;
            end
            if regCnt >= 4
                removeReg = removeRegLis{4};
                removeReg = uint16(removeReg);
                finalImg(removeReg(2):removeReg(2) + removeReg(4), removeReg(1):removeReg(1) + removeReg(3), :) = 0;
            end
        end

        % output the masked image
        if debugMode
            imgOutputFn = debugImgFn;
        else
            imgOutputFn = [imgOutputPath, '/', imgInputDir(i).name];
        end
        imwrite(finalImg, imgOutputFn);

        % add exif info
        exiftoolExec = '';
        osStr = computer;
        if osStr == 'PCWIN64'
            exiftoolExec = 'exiftool.exe';
        elseif osStr == 'GLNXA64'
            exiftoolExec = 'exiftool';
        end
        cmd = [exiftoolExec, ' -overwrite_original -TagsFromFile', ' "', imgInputFn, '" "', imgOutputFn, '"'];
        if debugMode
            display(cmd)
        else
            [status, info]=system(cmd);
        end
    end
end
