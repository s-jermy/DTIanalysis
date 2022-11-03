function ha_dicom = SegmentalHAAnalysis(map_dicom,info,contours)

ha_dicom = [];

cardiacphases = fieldnames(map_dicom);

% nmean = @(v) mean(v,'omitnan');
% nstd = @(v) std(v,'omitnan');

for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        Segments = [];
        map_struct = map_dicom.(cardiacphases{i}).(slicelocation{j});
        
        if isempty(map_struct)
            ha_dicom.(cardiacphases{i}).(slicelocation{j}).SegmentedData = Segments;
            continue;
        end
        
        h = waitbar(0,'Performing helix angle segmental analysis...');
        
        PixelSpacing = info{j}.PixelSpacing;
        
        epi = contours.epi{j};
        endo = contours.endo{j};
        M_myo = contours.myoMask{j};
        M_depth = contours.depthMask{j};
        M_depth(~M_myo) = nan;
        rvi = contours.rvi{j};
        apex_flag = strcmp(slicelocation{j},'Apex');
        
        centroid = mean(cat(1,epi,endo),1); %centre of the lv
        
        segs = 6; %base and mid
        if apex_flag
            segs = 4;
        end
        angle = 360/segs;
        
        RefVect = centroid - rvi; %vector pointing from centre to anterior rv insertion
        RefVectAngle = atan2d(RefVect(1),RefVect(2)); %angle of vector       
        RadVect = repmat(centroid,[size(epi,1) 1]) - epi; %vectors pointing along radial direction
        RadVectAngle = atan2d(RadVect(:,1),RadVect(:,2)); %angles of vectors
        RadVectAngle = RadVectAngle - RefVectAngle; %rotate angles so that rv insertion vector is at 0 deg
        AHAseg = floor(mod(RadVectAngle,360)/angle)+1; %which segment does each vector belong to
        
        ha = map_struct.radians.HA_filt;
        
        lowb = fieldnames(ha);
        n = length(lowb);
        count = 0;
        
        for lb=1:n
            highb = fieldnames(ha.(lowb{lb}));
            for hb=1:length(highb)
                count = count+1;
                
                depth = nan([size(epi,1) 1]);
                grad = nan([size(epi,1) 1]);
                depthSeg = cell(1,segs);
                gradSeg = cell(1,segs);
                
                TMPha = ha.(lowb{lb}).(highb{hb});
                TMPha(~M_myo) = nan;
                
                for k=1:size(epi,1)
                    helix_prof = improfile(TMPha,[centroid(1) epi(k,1)],[centroid(2) epi(k,2)]);
                    grad_prof = improfile(M_depth,[centroid(1) epi(k,1)],[centroid(2) epi(k,2)]);
                    
                    pxLength = PixelSpacing(1) * norm(RadVect(k,:)) / length(helix_prof); %assuming square pixels
                    
                    valid = find(~isnan(helix_prof));
                    haValid = helix_prof(valid);
                    
                    if length(haValid)>1
                        if (max(valid)-min(valid))~=(length(haValid)-1)
                            warning('Something weird here');
                        end
                        
                        range = length(haValid)-1;
                        x = (0:range) + .5;
                        x_length = x'*pxLength; %depth into tissue (endo->epi)
                        x_grad = grad_prof(valid)*100; %percent depth into tissue (endo->epi)

                        [p,~] = polyfit(x_length,haValid,1);
                        [p1,S1] = polyfit(x_grad,haValid,1);
                        
                        R2 = 1 - (S1.normr/norm(haValid-mean(haValid)))^2;
%                         R2(k,2) = p1(1);
                        if R2>=0.25 && p1(1)<0
                            depth(k) = 180/pi*p(1);
                            grad(k) = 180/pi*p1(1);

                            depthSeg{AHAseg(k)} = cat(1,depth(k),depthSeg{AHAseg(k)});
                            gradSeg{AHAseg(k)} = cat(1,grad(k),gradSeg{AHAseg(k)});
                        end
                    end
                end
                
                Segments.means.HAd.(lowb{lb}).(highb{hb}) = cellfun(@mean,depthSeg);
                Segments.means.HAg.(lowb{lb}).(highb{hb}) = cellfun(@mean,gradSeg);
                Segments.stds.HAd.(lowb{lb}).(highb{hb}) = cellfun(@std,depthSeg);
                Segments.stds.HAg.(lowb{lb}).(highb{hb}) = cellfun(@std,gradSeg);
                
                Segments.means.HAd.(lowb{lb}).(highb{hb})(end+1) = mean(depth,'omitnan');
                Segments.means.HAg.(lowb{lb}).(highb{hb})(end+1) = mean(grad,'omitnan');
                Segments.stds.HAd.(lowb{lb}).(highb{hb})(end+1) = std(depth,'omitnan');
                Segments.stds.HAg.(lowb{lb}).(highb{hb})(end+1) = std(grad,'omitnan');
                
                waitbar(count/(n*(n+1)/2),h);
            end
        end
        
        ha_dicom.(cardiacphases{i}).(slicelocation{j}).SegmentedData = Segments;
        
        close(h);
    end
end

end