function [nfo2,contours2] = DefineROI(trace,nfo,contours)
% in:
% trace - structure containing average image for each b-value
% nfo - structure containing info about dicom images
% contours - structure containting contours
%
% out:
% nfo2 - structure containing info about dicom images
% contours2 - structure containting contours
% 
% description:
% draw an endo and epi roi for each slice and create masks

nfo2 = nfo;
contours2 = contours;
P_Endo={};
P_Epi={};
P_RVI={};
M_LV={};
M_Depth={};

for i = 1:length(trace)
    if isempty(trace{i})
        P_Endo{i} = [];
        P_Epi{i} = [];
        P_RVI{i} = [];
        M_LV{i} = [];
        M_Depth{i} = [];
        continue
    end
    
    RoiImage = trace{i}{2}; %use the b50 trace of each slice to draw ROIs
    [Xq,Yq] = meshgrid(1:size(RoiImage,2),1:size(RoiImage,1));
    
    try %reuse and edit previously defined contours        
        endo = contours.endo{i}; %make sure these variables exist otherwise create a new set
        epi = contours.epi{i};
        rvi = contours.rvi{i};
        [epi,endo,rvi] = EditContours(RoiImage,epi,endo,rvi);
    catch
        [epi,endo,rvi] = Segmentation(RoiImage,200);
    %     epi = FlipCWtoACW(contours2.epi{i});
    %     endo = FlipCWtoACW(contours2.endo{i});
    end
    P_Endo{i} = endo;
    P_Epi{i} = epi;
    P_RVI{i} = rvi;
    
    epimask = inpolygon(Xq,Yq,epi(:,1),epi(:,2));
    endomask = inpolygon(Xq,Yq,endo(:,1),endo(:,2));
    myo = xor(epimask,endomask);
    M_LV{i} = myo;

    Endo_Line = zeros(size(endo));
    Epi_Line = ones(size(epi));
    PosRoi = cat(1,epi,endo);
    LineRoi = cat(1,Epi_Line,Endo_Line);
    F = scatteredInterpolant(PosRoi(:,1),PosRoi(:,2),LineRoi(:,1),'linear','none');
    M_Depth{i} = F(Xq,Yq);
    
    nfo2{i}.contoursDefined = 1;
end
%%% Create a Depth Mask
    
contours2.epi = P_Epi; %epicardium polygon
contours2.endo = P_Endo; %endocardium polygon
contours2.rvi = P_RVI; %rvi point
contours2.myoMask = M_LV; %LV mask
contours2.depthMask = M_Depth; %depth mask
    
end

function [epi, endo, rvi] = Segmentation(IM, nInterp)
% in:
% IM - 2D image matrix to be segmented
% nInterp - number of interpolated points
%
% out:
% epi - [n x 2] of points for epicardium interpolated to nInterp
% endo - [n x 2] of points for endocardium interpolated to nInterp
% rvi - RV insertion point
% 
% description:
% segmentation sub function, creates rois with standard size
%
% Written by Eric Aliotta and Ilya Verzhbinsky, UCLA. 07/13/2016.
% Modified by Kévin Moulin
% Ennis Lab @ UCLA; http://mrrl.ucla.edu
% Modified by Stephen Jermy - not bothering with splines/akima instead;
% added interparc to get equally spaced points around ROIs; ROIs are always
% defined ACW now

figure;
ax = imagesc(IM,[min(IM(:)) max(IM(:))]); % here just view the image you want to base your borders on
% ax.YData = fliplr(ax.YData);
% ax.Parent.YDir = 'normal';
colormap('gray');title(gca,'Draw an ROI around the epicardium');axis equal

epiRoi = drawpolyline('Color',[0 1 0]);customWait(epiRoi);
epiRoi.Label = 'Epicardium';epiRoi.LabelAlpha = 0.6;

title(gca,'Draw an ROI around the endocardium');
endoRoi = drawpolyline('Color',[1 0 0]);customWait(endoRoi);
endoRoi.Label = 'Endocardium';endoRoi.LabelAlpha = 0.6;

title(gca,'Select the anterior interventricular junction');
rviRoi = drawpoint('Label','RVI','Color',[0 0 1]);

epiPos = epiRoi.Position;
epiPos(end+1,:) = epiPos(1,:); %add first point to end for interpolation

endoPos = endoRoi.Position;
endoPos(end+1,:) = endoPos(1,:); %add first point to end for interpolation

rviPos = rviRoi.Position;

epiRoi.Visible = 'off';
endoRoi.Visible = 'off';
rviRoi.Visible = 'off';

title(gca,'');

epiInterp = linspace(1,size(epiPos,1),nInterp+1); %interpolate one extra point so it can be removed later
epiInterp = epiInterp(1:end-1); %remove last point, it is the same as the first
tmp_epi(:,1) = interp1(epiPos(:,1),epiInterp,'makima');
tmp_epi(:,2) = interp1(epiPos(:,2),epiInterp,'makima');
epi2 = interparc(nInterp,tmp_epi(:,1),tmp_epi(:,2),'pchip'); %gives equally spaced points around ROI

endoInterp = linspace(1,size(endoPos,1),nInterp+1); %interpolate one extra point so it can be removed later
endoInterp = endoInterp(1:end-1); %remove last point, same as first
tmp_endo(:,1) = interp1(endoPos(:,1),endoInterp,'makima');
tmp_endo(:,2) = interp1(endoPos(:,2),endoInterp,'makima');
endo2 = interparc(nInterp,tmp_endo(:,1),tmp_endo(:,2),'pchip'); %gives equally spaced points around ROI

rvi = rviPos;

epi = FlipCWtoACW(epi2); %sj - ensure ROIs are anticlockwise, needed for dti calc
endo = FlipCWtoACW(endo2);

hold on;
plot(epi(:,1),epi(:,2),'g.-','LineWidth',2.25)
plot(endo(:,1),endo(:,2),'r.-','LineWidth',2.25)
plot(rvi(:,1),rvi(:,2),'bx','LineWidth',2.25)
hold off;

pause(1);

close;

end

function [epi, endo, rvi] = EditContours(IM, epi, endo, rvi)
% in:
% IM - 2D image matrix
% epi - [n x 2] of points for epicardium
% endo - [n x 2] of points for endocardium
% rvi - RV insertion point
%
% out:
% epi - [n x 2] of points for epicardium
% endo - [n x 2] of points for endocardium
% rvi - RV insertion point

figure;
ax = imagesc(IM,[min(IM(:)) max(IM(:))]); % here just view the image you want to base your borders on
% ax.YData = fliplr(ax.YData);
% ax.Parent.YDir = 'normal';
colormap('gray');title(gca,'Edit epicardium ROI');axis equal

nInterp = size(epi,1);

epiRoi = drawpolyline('Color',[0 1 0],'Position',epi(1:5:end,:));customWait(epiRoi);
epiRoi.Label = 'Epicardium';epiRoi.LabelAlpha = 0.6;

title(gca,'Edit endocardium ROI');
endoRoi = drawpolyline('Color',[1 0 0],'Position',endo(1:5:end,:));customWait(endoRoi);
endoRoi.Label = 'Endocardium';endoRoi.LabelAlpha = 0.6;

title(gca,'Edit anterior LV/RV junction (Previous ROIs still editable)');
rviRoi = drawpoint('Color',[0 0 1],'Position',rvi);customWait(rviRoi);
rviRoi.Label = 'RVI';rviRoi.LabelAlpha = 0.6;

epiPos = epiRoi.Position;
epiPos(end+1,:) = epiPos(1,:); %add first point to end for interpolation

endoPos = endoRoi.Position;
endoPos(end+1,:) = endoPos(1,:); %add first point to end for interpolation

rviPos = rviRoi.Position;

epiRoi.Visible = 'off';
endoRoi.Visible = 'off';
rviRoi.Visible = 'off';

title(gca,'');

epiInterp = linspace(1,size(epiPos,1),nInterp+1); %interpolate one extra point so it can be removed later
epiInterp = epiInterp(1:end-1); %remove last point, it is the same as the first
tmp_epi(:,1) = interp1(epiPos(:,1),epiInterp,'makima');
tmp_epi(:,2) = interp1(epiPos(:,2),epiInterp,'makima');
epi2 = interparc(nInterp,tmp_epi(:,1),tmp_epi(:,2),'pchip'); %gives equally spaced points around ROI

endoInterp = linspace(1,size(endoPos,1),nInterp+1); %interpolate one extra point so it can be removed later
endoInterp = endoInterp(1:end-1); %remove last point, same as first
tmp_endo(:,1) = interp1(endoPos(:,1),endoInterp,'makima');
tmp_endo(:,2) = interp1(endoPos(:,2),endoInterp,'makima');
endo2 = interparc(nInterp,tmp_endo(:,1),tmp_endo(:,2),'pchip'); %gives equally spaced points around ROI

rvi = rviPos;

epi = FlipCWtoACW(epi2); %sj - ensure ROIs are anticlockwise, needed for dti calc
endo = FlipCWtoACW(endo2);

hold on;
plot(epi(:,1),epi(:,2),'g.-','LineWidth',2.25)
plot(endo(:,1),endo(:,2),'r.-','LineWidth',2.25)
plot(rvi(:,1),rvi(:,2),'bx','LineWidth',2.25)
hold off;

pause(1);

close;

end

function [poly2] = FlipCWtoACW(poly)
% in:
% poly - ROI polygon
% 
% out:
% poly2 - ROI polygon oriented ACW
% 
% description:
% kind of a random function to orient the rois in an ACW direction. I
% tended to draw my contours in a CW direction and that messes with the
% angles in later functions

x = poly(:,1)';
y = poly(:,2)';

x = x-mean(x); %remove bias
y = y-mean(y);

X = fft(x);
Y = fft(y);
[~, idx_x] = max(abs(X));
[~, idx_y] = max(abs(Y));
px = angle(X(idx_x));
py = angle(Y(idx_y));
phase_lag = py - px;

%wrap phase
if phase_lag>pi
    phase_lag = phase_lag-2*pi;
elseif phase_lag<=-pi
    phase_lag = phase_lag+2*pi;
end

if phase_lag<0 %does x lag behind y? - change CW to ACW by reversing order
    poly2 = flip(poly,1);
%     disp('That one was CW');
else
    poly2 = poly; %already ACW
%     disp('Already ACW');
end

end