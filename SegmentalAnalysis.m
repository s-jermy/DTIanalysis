function segment_dicom = SegmentalAnalysis(map_dicom,av_dicom,contours)

% in:
% map_dicom - struct containing diffusion maps
% av_dicom - struct containing averaged diffusion images
% contours - struct containting contours
% 
% out:
% segment_dicom - struct containing segmented diffusion outputs
% 
% description:
% extract means and stds using aha segments

segment_dicom = [];

cardiacphases = fieldnames(map_dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        Segments = [];
        TMPav = av_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData;
        
        if isempty(TMPav)
            segment_dicom.(cardiacphases{i}).(slicelocation{j}).SegmentedData = Segments;
            continue;
        end
        
        h = waitbar(0,'Performing segmental analysis...');

        epi = contours.epi{j};
        endo = contours.endo{j};
        M_myo = contours.myoMask{j};
%         M_depth = contours.depthMask{j};
        rvi = contours.rvi{j};
        apex_flag = strcmp(slicelocation{j},'Apex');

        [segROI,~] = defineSegmentalROI(TMPav,epi,endo,M_myo,rvi,apex_flag);
%         depROI = defineDepthROI(M_depth,5);

        md = map_dicom.(cardiacphases{i}).(slicelocation{j}).MD;
        fa = map_dicom.(cardiacphases{i}).(slicelocation{j}).FA;
        ad = map_dicom.(cardiacphases{i}).(slicelocation{j}).AD;
        rd = map_dicom.(cardiacphases{i}).(slicelocation{j}).RD;
%         ha = map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.HA_filt;
        e2a = map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.E2A;
        tra = map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.TRA;
        sa = map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.SA;

        lowb = fieldnames(md);
        n = length(lowb);
        count = 0;
    
        for lb=1:n
            highb = fieldnames(md.(lowb{lb}));
            for hb=1:length(highb)
                count = count+1;
                
                TMPmd = md.(lowb{lb}).(highb{hb});
                TMPfa = fa.(lowb{lb}).(highb{hb});
                TMPad = ad.(lowb{lb}).(highb{hb});
                TMPrd = rd.(lowb{lb}).(highb{hb});
%                 TMPha = ha.(lowb{lb}).(highb{hb});
                TMPe2a = e2a.(lowb{lb}).(highb{hb});
                TMPtra = tra.(lowb{lb}).(highb{hb});
                TMPsa = sa.(lowb{lb}).(highb{hb});

                for k=1:length(segROI)
                    sMD = regionprops(segROI{k},TMPmd,'PixelValues');
                    sFA = regionprops(segROI{k},TMPfa,'PixelValues');
                    sAD = regionprops(segROI{k},TMPad,'PixelValues');
                    sRD = regionprops(segROI{k},TMPrd,'PixelValues');
                    sE2A = regionprops(segROI{k},TMPe2a,'PixelValues');
                    sTRA = regionprops(segROI{k},TMPtra,'PixelValues');
                    sSA = regionprops(segROI{k},TMPsa,'PixelValues');
                    Segments.means.MD.(lowb{lb}).(highb{hb})(k) = mean(cat(1,sMD(:).PixelValues));
                    Segments.means.FA.(lowb{lb}).(highb{hb})(k) = mean(cat(1,sFA(:).PixelValues));
                    Segments.means.AD.(lowb{lb}).(highb{hb})(k) = mean(cat(1,sAD(:).PixelValues));
                    Segments.means.RD.(lowb{lb}).(highb{hb})(k) = mean(cat(1,sRD(:).PixelValues));
                    Segments.stds.MD.(lowb{lb}).(highb{hb})(k) = std(cat(1,sMD(:).PixelValues));
                    Segments.stds.FA.(lowb{lb}).(highb{hb})(k) = std(cat(1,sFA(:).PixelValues));
                    Segments.stds.AD.(lowb{lb}).(highb{hb})(k) = std(cat(1,sAD(:).PixelValues));
                    Segments.stds.RD.(lowb{lb}).(highb{hb})(k) = std(cat(1,sRD(:).PixelValues));
                    Segments.means.absE2A.(lowb{lb}).(highb{hb})(k) = mean(abs(cat(1,sE2A(:).PixelValues)))*180/pi;
                    Segments.means.E2A.(lowb{lb}).(highb{hb})(k) = circ_mean(2*cat(1,sE2A(:).PixelValues))*180/pi/2;
                    Segments.means.TRA.(lowb{lb}).(highb{hb})(k) = circ_mean(2*cat(1,sTRA(:).PixelValues))*180/pi/2;
                    Segments.means.SA.(lowb{lb}).(highb{hb})(k) = circ_mean(2*cat(1,sSA(:).PixelValues))*180/pi/2;
                    Segments.stds.absE2A.(lowb{lb}).(highb{hb})(k) = std(abs(cat(1,sE2A(:).PixelValues)))*180/pi;
                    Segments.stds.E2A.(lowb{lb}).(highb{hb})(k) = circ_std(2*cat(1,sE2A(:).PixelValues))*180/pi/2;
                    Segments.stds.TRA.(lowb{lb}).(highb{hb})(k) = circ_std(2*cat(1,sTRA(:).PixelValues))*180/pi/2;
                    Segments.stds.SA.(lowb{lb}).(highb{hb})(k) = circ_std(2*cat(1,sSA(:).PixelValues))*180/pi/2;
                end
                
%                 for k=1:length(depROI)
%                     sHA = regionprops(depROI{k},TMPha,'PixelValues');
%                     Segments.means.HA.(lowb{lb}).(highb{hb})(k) = circ_mean(cat(1,sHA(:).PixelValues));
%                     Segments.stds.HA.(lowb{lb}).(highb{hb})(k) = circ_std(cat(1,sHA(:).PixelValues));
%                 end
                
                sMD = regionprops(M_myo,TMPmd,'PixelValues');
                sFA = regionprops(M_myo,TMPfa,'PixelValues');
                sAD = regionprops(M_myo,TMPad,'PixelValues');
                sRD = regionprops(M_myo,TMPrd,'PixelValues');
                sE2A = regionprops(M_myo,TMPe2a,'PixelValues');
                sTRA = regionprops(M_myo,TMPtra,'PixelValues');
                sSA = regionprops(M_myo,TMPsa,'PixelValues');
                Segments.means.MD.(lowb{lb}).(highb{hb})(end+1) = mean(cat(1,sMD(:).PixelValues));
                Segments.means.FA.(lowb{lb}).(highb{hb})(end+1) = mean(cat(1,sFA(:).PixelValues));
                Segments.means.AD.(lowb{lb}).(highb{hb})(end+1) = mean(cat(1,sAD(:).PixelValues));
                Segments.means.RD.(lowb{lb}).(highb{hb})(end+1) = mean(cat(1,sRD(:).PixelValues));
                Segments.stds.MD.(lowb{lb}).(highb{hb})(end+1) = std(cat(1,sMD(:).PixelValues));
                Segments.stds.FA.(lowb{lb}).(highb{hb})(end+1) = std(cat(1,sFA(:).PixelValues));
                Segments.stds.AD.(lowb{lb}).(highb{hb})(end+1) = std(cat(1,sAD(:).PixelValues));
                Segments.stds.RD.(lowb{lb}).(highb{hb})(end+1) = std(cat(1,sRD(:).PixelValues));
                Segments.means.absE2A.(lowb{lb}).(highb{hb})(end+1) = mean(abs(cat(1,sE2A(:).PixelValues)))*180/pi;
                Segments.means.E2A.(lowb{lb}).(highb{hb})(end+1) = circ_mean(2*cat(1,sE2A(:).PixelValues))*180/pi/2;
                Segments.means.TRA.(lowb{lb}).(highb{hb})(end+1) = circ_mean(2*cat(1,sTRA(:).PixelValues))*180/pi/2;
                Segments.means.SA.(lowb{lb}).(highb{hb})(end+1) = circ_mean(2*cat(1,sSA(:).PixelValues))*180/pi/2;
                Segments.stds.absE2A.(lowb{lb}).(highb{hb})(end+1) = std(abs(cat(1,sE2A(:).PixelValues)))*180/pi;
                Segments.stds.E2A.(lowb{lb}).(highb{hb})(end+1) = circ_std(2*cat(1,sE2A(:).PixelValues))*180/pi/2;
                Segments.stds.TRA.(lowb{lb}).(highb{hb})(end+1) = circ_std(2*cat(1,sTRA(:).PixelValues))*180/pi/2;
                Segments.stds.SA.(lowb{lb}).(highb{hb})(end+1) = circ_std(2*cat(1,sSA(:).PixelValues))*180/pi/2;

                waitbar(count/(n*(n+1)/2),h);
            end
        end
    
        segment_dicom.(cardiacphases{i}).(slicelocation{j}).SegmentedData = Segments;
    
        close(h);
    end
end

end

function [segROI,segMask] = defineSegmentalROI(av_dicom,epi,endo,M_myo,rvi,apex)
% in:
% av_dicom - struct containing averaged diffusion images
% epi - epicardium polygon
% endo - endocardium polygon
% M_myo - LV myocardium mask
% rvi - RVI point
% apex - is this an apical slice? t/f
% 
% out:
% segROI - AHA ROI segments
% segMask - segment mask
% 
% description:
% create segment masks

aver = av_dicom(1).image;

segs = 6;
if apex
    segs = 4;
end
angle = 360/segs;

hf = figure;
imshow(aver,[]); colormap('gray');

masksize = size(aver);
[xx, yy] = meshgrid(1:masksize(2),1:masksize(1));

M_epi = inpolygon(xx,yy,epi(:,1),epi(:,2));
% M_endo = inpolygon(xx,yy,endo(:,1),endo(:,2));

centroid = mean(cat(1,epi,endo),1)'; %centre of the lv

s = regionprops(M_epi,'MajorAxisLength');

RefVect = rvi' - centroid;
RefVect = RefVect.*s.MajorAxisLength.*0.75./norm(RefVect);
RefVect = ([cosd(angle) -sind(angle);sind(angle) cosd(angle)]*RefVect); % to match AHA

rotation = [cosd(-angle) -sind(-angle);sind(-angle) cosd(-angle)];

for i=1:segs
    RefVectRot = rotation*RefVect;
    
    seg = impoly(gca,[centroid, centroid+RefVect, centroid+RefVectRot]');
    M_seg = seg.createMask();
    segROI{i} = and(M_myo,M_seg);
    segMask{i} = M_seg;
    delete(seg);
    
    RefVect = RefVectRot;
end

close(hf);

end

function depROI = defineDepthROI(M_depth,levels)

% in:
% M_depth - LV myocardium mask
% levels - number of depth levels (force to be positive and odd)
% 
% out:
% depROI - depth ROI segments
% 
% description:
% create depth masks

levels = abs(levels);
if mod(levels,2)==0
    levels = levels+1;
end

for i=1:levels
    dep1 = M_depth>((i-1)/levels);
    dep2 = M_depth<=(i/levels);
    depROI{i} = and(dep1,dep2);
end

end