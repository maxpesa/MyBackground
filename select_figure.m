%{v0.1 This program evaluates the differences between the
%frames and the background, creates a mask and replaces
%with the new background. Comparisons are very inefficients
%}

video = 'multipic2.mp4';
newBackground = 'bovaro_resize.jpg';

%function select_figure(video, newBackground)

% get names without extension
[~,videoName,~] = fileparts(video);
[~,backgroundName,~] = fileparts(newBackground);
% create video object
VObj=VideoReader(video);
% get number of frames
numFrames = get(VObj, 'NumberOfFrames');
% get frame rate
FrameRate = get(VObj,'FrameRate');

%get first frame as background
background = read(VObj,1); 
%get size of the frames
[ysize,xsize,~] = size(background);

%precision parameters for substitution
sensitivity = 3;
blockSize = 10;

%image for new background
newBack=imread(newBackground); %TODO deal with different sizes

% PREPARE VIDEO WRITER
% If target directory does not exist, create it
foldername = 'video';
if ~exist(foldername,'dir')
    disp('creating folder')
    mkdir(foldername);
end
%outputVideo =
%VideoWriter(strcat(foldername,'/',videoName,"_",backgroundName,".avi"));
%%TODO perchè ritorna errore folder video non esiste?
outputVideo = VideoWriter('video/bov4.avi');
outputVideo.FrameRate = FrameRate;
open(outputVideo);
%% GET ALL THE FRAMES %TODO deal with sizes not multiple of block size
for index=2:numFrames %iterate over frames
    disp("computing frame "+num2str(index));
    %read frames
    vidFrame = read(VObj,index);
    
    %% CREATE MASK AND REPLACE BACKGROUND
    %mask -> zero if sub with new background, one otherwise
    mask = zeros(ysize,xsize,3);
    %matrix of differences
    diff = abs(background-vidFrame);
    %build mask
    for row=1:blockSize:ysize
       for col=1:blockSize:xsize
            if(diff(row,col,1)> sensitivity || diff(row,col,2) > sensitivity || diff(row,col,3)>sensitivity)
               if(row+blockSize < ysize && col+blockSize < xsize)
               mask(row:row+blockSize,col:col+blockSize,1:3) = 1;
               end
            end
       end
    end
    mask = uint8(mask);
    nmask = round(~mask);
    nmask = uint8(nmask);
    %blocks selection
    newFrame = vidFrame.*mask;
    newBackgroundIm = newBack.*nmask;
    %add to video the overlap
    writeVideo(outputVideo,newFrame+newBackgroundIm);
    
end
close(outputVideo);
%end

