%% New DTI script
function DTIanalysis(varargin)
% DTIANALYSIS({saveTag} {batchFlag} {batchInd})
%     in:
%     saveTag - name of folder (or project) where data will be saved
%     batchFlag - flag to set if StartScript will be running multiple cases
%     at once
%     batchInd - batch index to start from, useful if execution fails
%     halfway though a batch
%     
%     description:
%     Main script for running DTIanalysis. If no inputs are given, it is
%     equivalent to running DTIanalysis('default',0).
% 
%     REQUIRED TOOLBOXES:
%     Curve Fitting toolbox
%     Image Processing toolbox

narginchk(0,3)

% clearvars
close all

addpath(genpath('tools')); %add tools and subfolders to the search path

%% variable check
if nargin<1 %default operation
    varargin{1} = 'default'; %saveTag
end

if nargin<2
    varargin{2} = 0; %batchFlag
end

if nargin<3 && varargin{2}
    varargin{3} = 1; %batchInd
end

%% save directory for output files for different projects
saveTag = varargin{1};
saveTagCell = regexp(saveTag,'_','split');
if ispc
    switch saveTagCell{1}
        case 'steve'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData';
        case 'zak'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData\Zak';
        case 'test'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData';
        otherwise
            dataDirParent = pwd;
    end
elseif ismac
    switch saveTagCell{1}
        case 'steve'
            dataDirParent = '/Volumes/mri/UserFolders/jermy/DiffusionData';
        otherwise
            dataDirParent = pwd;
    end
end

%%
dicomdict('set','dicom-dict-dti.txt'); %set dicom dictionary for added dicom attributes

additionalID = 'glyph_dti'; %sj - tags for changes
lb_labels = {'b50','b350'}; %labels of low b-values to output - change to {} for all
hb_labels = {'b350','b450','b550','b650'}; %labels of high b-values to output - change to {} for all
doAffineReg = true; %sj - true=perform affine registration / false=perform simple registration
glyphs = false; %sj - show superquad glyphs of tensors
lastFunc = '';

%% check/create folders
batchFlag = varargin{2};
dataDir = '';

if batchFlag
    dataDir = ChooseFolder(saveTag,varargin{3});
    dataDir = fullfile(dataDirParent,dataDir); %get folder of current subject
end

if isempty(dataDir)
    dataDir = uigetdir(dataDirParent); %choose bottom level folder of images - i.e. folder containing no subfolders
end
dirlisting = dir(fullfile(dataDir,'**')); %find all in the main directory including subfolders

splitdir = regexp(dataDir,filesep,'split');
splitdir = splitdir(~cellfun('isempty',splitdir));
additionalID = [additionalID '_' splitdir{end}];
newfolder = false;

try
    dcmInfo = LoadFirstDicom(dirlisting); %load first valid dicom file from the chosen directory
catch
    tmp = strsplit(splitdir{end-1},'_');
    dcmInfo.PatientID = char(join(tmp(2:end),'_'));
end

saveDir = fullfile(saveTag,dcmInfo.PatientID,additionalID);
% warning('off','MATLAB:MKDIR:DirectoryExists');

try
    if ~isfolder(saveDir)
        mkdir(saveDir); %create a new folder for the save directory
        newfolder = true;
    end
catch %unable to make directory (usually because of missing ID or an illegal character)
    saveDir = fullfile(saveTag,dcmInfo.PatientName.FamilyName,additionalID);
    try %try again with patient name
        if ~isfolder(saveDir)
            mkdir(saveDir);
            newfolder = true;
        end
    catch
        regex = '[\W]'; %in case there are illegal characters
        pat = regexpPattern(regex);
        ind = strfind(dcmInfo.PatientID,pat); %find and remove illegal characters
        dcmInfo.PatientID(ind)='';
        saveDir = fullfile(saveTag,dcmInfo.PatientID,additionalID);
        if ~isfolder(saveDir)
            mkdir(saveDir);
            newfolder = true;
        end
    end
end
% warning('on','MATLAB:MKDIR:DirectoryExists');

%% load previous files if we have run this before
if ~newfolder
    try
        load(fullfile(saveDir,'lastFunc.mat')); %if an operation failed part way though execution lastFunc keeps track of the last succesful function
    catch
        warning('No vaild files were found in that directory. Continuing...');
        lastFunc = '';
    end
    
    %%{
    lastFunc = 'Registration'; %override
    %}
    
    switch lastFunc
        case 'AnalyseDicoms' %next CategoriseAndConstrain
            %basically just redo everything
        case 'CategoriseAndConstrain' %next RejectImages
            load(fullfile(saveDir,'Current.mat'),'Current*');
            load(fullfile(saveDir,'contours.mat'),'contours');
        case 'RejectImages' %next Registration
            load(fullfile(saveDir,'Clean.mat'),'Clean*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
                CleanInfo{l}.registrationComplete = 0;
            end
        case 'Registration' %next DefineROI
            load(fullfile(saveDir,'Clean.mat'),'Clean*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
            end
        case 'DefineROI' %next hrCorrection
            load(fullfile(saveDir,'Clean.mat'),'Clean*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'hrCorrection' %next Average
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'Average' %next CalculateTensor
            load(fullfile(saveDir,'CleanAver.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'CalculateTensor' %next DTIMaps
            load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
            load(fullfile(saveDir,'CleanAver.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'DTIMaps' %next SegmentalAnalysis
            load(fullfile(saveDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(saveDir,'CleanAver.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
            end
        case 'SegmentalAnalysis' %next savePNGs
            load(fullfile(saveDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(saveDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
            end
        case 'savePNGs' %next WriteExcelSheet or...
            load(fullfile(saveDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            if glyphs %next GlyphDTI
                load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
                load(fullfile(saveDir,'CleanMaps.mat'),'Clean*');
                load(fullfile(saveDir,'contours.mat'),'contours');
            end
        case 'GlyphDTI' %next WriteExcelSheet
            load(fullfile(saveDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        otherwise %start again
            lastFunc = ''; %just redo everything
    end
end

save(fullfile(saveDir,'Paths.mat'),'dataDir','saveDir','doAffineReg','glyphs','additionalID','lb_labels','hb_labels');

%% load images and sort
if isempty(lastFunc) || strcmp(lastFunc,'AnalyseDicoms')
    InitialDicoms = LoadDicom(dirlisting); %✓
    % lastFunc = 'LoadDicom';

    [ProvisionalDiffusionDicoms,ProvisionalInfo] = AnalyseDicoms(InitialDicoms); %✓
    lastFunc = 'AnalyseDicoms';

    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    % save(fullfile(saveDir,'Provisional.mat'),'ProvisionalDiffusionDicoms','ProvisionalInfo');

    [CurrentSlice,CurrentInfo,contours] = CategoriseAndConstrain(ProvisionalDiffusionDicoms,ProvisionalInfo); %✓
    lastFunc = 'CategoriseAndConstrain';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Current.mat'),'CurrentSlice','CurrentInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
end

%% remove low quality images
if strcmp(lastFunc,'CategoriseAndConstrain')
    [CurrentInfo,AHASliceLocations,figures] = RejectImages(CurrentSlice,CurrentInfo,contours); %✓
    lastFunc = 'RejectImages';
    SaveFigures(figures,saveDir,'RejectImages');

    %% create clean structures
    [CleanData,CleanInfo] = CleanStruct(CurrentSlice,CurrentInfo,figures,AHASliceLocations); %✓
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Clean.mat'),'CleanData','CleanInfo');
    % save(fullfile(saveDir,'contours.mat'),'contours');

    close all; clear figures;
end

%% register and segment
if strcmp(lastFunc,'RejectImages')
    [CleanData,CleanInfo,Trace] = Registration(CleanData,CleanInfo,contours,doAffineReg); %✓
    lastFunc = 'Registration';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'Trace.mat'),'Trace');
end

if strcmp(lastFunc,'Registration')
    [CleanInfo,contours] = DefineROI(Trace,CleanInfo,contours); %✓
%     [CleanInfo,contours] = ResampleROI(CleanInfo,contours);
    lastFunc = 'DefineROI';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
end

%% apply corrections for heart rate and T1 relaxation
if strcmp(lastFunc,'DefineROI')
    [HRCorrData,HRCorrInfo] = hrAndT1Correction(CleanData,CleanInfo); %✓
    lastFunc = 'hrCorrection';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanHRcorr.mat'),'HRCorrData','HRCorrInfo');
end

%% get average images for each unique gradient direction
% should I get the SNR maps?
if strcmp(lastFunc,'hrCorrection')
    [CleanAverage,~] = Average(HRCorrData,HRCorrInfo); %✓ - fixed
    lastFunc = 'Average';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanAver.mat'),'CleanAverage');
end

%% begin actual DTI analysis
if strcmp(lastFunc,'Average')
    CleanTensor = CalculateTensor(CleanAverage); %✓
    lastFunc = 'CalculateTensor';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanTensor.mat'),'CleanTensor');
end

if strcmp(lastFunc,'CalculateTensor')
    CleanMaps = DTIMaps(CleanTensor,contours); %✓
    lastFunc = 'DTIMaps';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanMaps.mat'),'CleanMaps');
end

if strcmp(lastFunc,'DTIMaps')
    CleanSegments = SegmentalAnalysis(CleanMaps,CleanAverage,contours); %✓
    CleanHASegments = SegmentalHAAnalysis(CleanMaps,HRCorrInfo,contours); %✓
    CleanSegments = CombineSegs(CleanSegments,CleanHASegments);
    lastFunc = 'SegmentalAnalysis';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanSegs.mat'),'CleanSegments');
end

% export images and data to excel
if strcmp(lastFunc,'SegmentalAnalysis')
    savePNGs(CleanMaps,Trace,contours,saveDir,lb_labels,hb_labels); %✓
    lastFunc = 'savePNGs';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
end

if strcmp(lastFunc,'savePNGs')&&glyphs
    figures = GlyphDTI(CleanTensor,CleanMaps,contours,Trace,lb_labels,hb_labels);
    SaveGlyphs(figures,saveDir);
    lastFunc = 'GlyphDTI';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');

    close all; clear figures;
end

if strcmp(lastFunc,'savePNGs')||strcmp(lastFunc,'GlyphDTI')
    if (ispc)
        warning('off','MATLAB:MKDIR:DirectoryExists');
        [Excel, Workbook] = StartExcel; %✓
        WriteExcelSheet(Excel,Workbook,CleanSegments,HRCorrInfo,saveDir,lb_labels,hb_labels); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
        warning('on','MATLAB:MKDIR:DirectoryExists');
        saveAndCloseExcel(Excel,Workbook,saveDir,additionalID); %✓
    else
        WriteExcelSheetMac(CleanSegments,HRCorrInfo,saveDir,dcmInfo.PatientID,lb_labels,hb_labels); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
    end
end

%% fix matlab stupidity
% When you use plot/plot3/quiver/etc in Matlab it uses a right-handed
% coordinate sytem which makes sense. However, if you first use
% imshow/imagesc/etc Matlab will use a left-handed coordinate system for no
% obvious reason. This can be fixed by making some adjustments to the
% y-axis.

% figure;
% ax = imshow(Trace{1}{1},[]);
% ax.YData = fliplr(ax.YData);
% ax.Parent.YDir = 'normal';
end
