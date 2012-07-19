% RANSACFITHOMOGRAPHY - fits 2D homography using RANSAC
%
% Usage:   [H, inliers] = ransacfithomography(x1, x2, t)
%
% Arguments:
%          x1  - 2xN or 3xN set of homogeneous points.  If the data is
%                2xN it is assumed the homogeneous scale factor is 1.
%          x2  - 2xN or 3xN set of homogeneous points such that x1<->x2.
%          t   - The distance threshold between data point and the model
%                used to decide whether a point is an inlier or not. 
%                Note that point coordinates are normalised to that their
%                mean distance from the origin is sqrt(2).  The value of
%                t should be set relative to this, say in the range 
%                0.001 - 0.01  
%
% Note that it is assumed that the matching of x1 and x2 are putative and it
% is expected that a percentage of matches will be wrong.
%
% Returns:
%          H       - The 3x3 homography such that x2 = H*x1.
%          inliers - An array of indices of the elements of x1, x2 that were
%                    the inliers for the best model.
%
% See Also: ransac, homography2d, homography1d

% Copyright (c) 2004-2005 Peter Kovesi
% School of Computer Science & Software Engineering
% The University of Western Australia
% http://www.csse.uwa.edu.au/
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.

% February 2004 - original version
% July     2004 - error in denormalising corrected (thanks to Andrew Stein)
% August   2005 - homogdist2d modified to fit new ransac specification.

function [shift, inliers] = ransacfitshift(x1, x2, t)

    if ~all(size(x1)==size(x2))
        error('Data sets x1 and x2 must have the same dimension');
    end
    
    [rows,npts] = size(x1);
    if rows~=2 
        error('x1 and x2 must have 2 rows');
    end
    
    if npts <4 
        error('Must have at least 4 points to fit shift');
    end

    s = 4;
    
    fittingfn = @shiftfitting;
    distfn    = @shiftdist;
    degenfn   = @shiftdegen;
    % x1 and x2 are 'stacked' to create a 6xN array for ransac
    [shift, inliers, success] = ransac([x1; x2], fittingfn, distfn, degenfn, s, t);
    
    % Now do a final least squares fit on the data points considered to
    % be inliers.
    if(success == 1)
      shift = shiftfitting([x1(:,inliers); x2(:,inliers)]);
    else
      shift = zeros(2,1);
    end

function shift = shiftfitting(x)
    x1 = x(1:2,:);   % Extract x1 and x2 from x
    x2 = x(3:4,:);    

    shift = mean(x1-x2,2);

%----------------------------------------------------------------------
% Function to evaluate the symmetric transfer error of a homography with
% respect to a set of matched points as needed by RANSAC.

function [inliers, shift] = shiftdist(shift, x, t);
    
    x1 = x(1:2,:);   % Extract x1 and x2 from x
    x2 = x(3:4,:);    
    
    % find offset in x and y directions
    d2 = sum(abs(x1-(x2+repmat(shift,1,size(x2,2)))));
    inliers = find(abs(d2) < t);    
    %size(inliers);
    
    
%----------------------------------------------------------------------
% Function to determine if a set of 4 pairs of matched  points give rise
% to a degeneracy in the calculation of a homography as needed by RANSAC.
% This involves testing whether any 3 of the 4 points in each set is
% colinear. 
     
function r = shiftdegen(x)
    r = false; 
