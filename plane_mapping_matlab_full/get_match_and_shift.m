function [row_shift col_shift] = get_shift(s1,s2)
frames1 = s1.sift_frames;
descr1 = s1.sift_descr;
frames2 = s2.sift_frames;
descr2 = s2.sift_descr;
addpath('sift');
addpath('../');

shift = zeros(2,1);
if(numel(descr1) > 0 && numel(descr2) > 0)
    
    matches=siftmatch( descr1, descr2, 3) ;
    P1 = frames1(1:2,:); P2 = frames2(1:2,:);
    sift_corr1 = [P1(1,matches(1,:)) ; P1(2,matches(1,:))];
    sift_corr2 = [P2(1,matches(2,:)) ; P2(2,matches(2,:))];
    
    inliers = 0;
    num_matches = size(matches, 2);
    if(num_matches >= 4)
        % Try this a few times
        for i = 1:10
            [shift inliers] = ransacfitshift(sift_corr1, sift_corr2, 10);
            if(size(inliers,2) >= 4) break; end
        end
    end
end
col_shift = shift(1);
row_shift = shift(2);

end
