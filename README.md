# DTIanalysis

My contours are in an anti-clockwise direciton i.e. the x component of the contour's phase leads the y component.
The contour vectors, essentially the circumferential vector, are defined as:
	CircVect(i) = contour(i+1) - contour(i)
	If i is the last point in the array, then i+1=1
This means that each point in the circumferential vector tells you what to add to the same point in the contour to get to the next point.

The contour points and the circumferential vectors are then used to create an interpolant function that can be used to determine the circumferential vector
at any point in the image.
	
Circumferential vector - CircVect - anti-clockwise direction
Longitudinal vector - LongVect - out of screen/apex to base
Radial vector - RadVect - cross(long,circ) - center-out
Same as Ferreira et al 2014 JCMR

Helix angle
	The HA represents the orientation ofthe myofiber (projected in the local tangent plane) with respect to the circumferential direction.
	Moulin et al 2020 PlosOne

	The primary eigenvector E1 was then projected radially to the local wall tangent plane. HA was defined as the angle in this plane between the E1 projection and the 
	circumferential direction in the range −90 to 90 degrees, being positive (right-handed helix) if rotated counter-clockwise from the circumferential as viewed from 
	the outside, and negative (left-handed helix) if rotated clockwise.
	Ferreira et al 2014 JCMR
			
	The radial component of the E1 vector is removed
		E1RadProj = E1Vect - RadVect*dot(RadVect,E1Vect)
	Leaving the projection on the local wall tangent. The angle between the circumferential direction and the projection can then be measured.
	Using inverse tan, the ratio of the longitudinal component of the projection and the circumferential component can be used to calculate the HA.
		atan(dot(E1RadProj,LongVect)/dot(E1RadProj,CircVect))

Transverse angle
	The TA measures the angle between the myofiber direction projected onto the local horizontal plane (normal to the epicardium) and the circumferential direction.
	Moulin et al 2020 PlosOne
	
	A transverse angle of +90 is a fiber pointing toward the ventricular cavity, a transverse angle of -90 is a fiber pointing outward from the ventricular cavity.
	Lombaert et al 2012 IEEE TMI
	
	The longitudinal component of the E1 vector is removed
		E1LongProj = E1Vect - LongVect*dot(LongVect,E1Vect)
	Leaving the projection on the local short axis plane. The angle between the circumferential direction and the projection can then be measured.
	Using inverse tan, the ratio of the radial component of the projection and the circumferential component can be used to calculate the TRA.
		atan(dot(E1LongProj,RadVect)/dot(E1LongProj,CircVect))

Second eigenvector angle
	...after projecting E2 onto the plane normal to E1 projection (E2A)
	Moulin et al 2020 PlosOne
	
	The cross-myocyte plane, perpendicular to E1, was then calculated for each voxel. Then E2 was projected onto this plane and E2A calculated in it, between E2 and the 
	illustrated cross-myocyte direction. This angle was measured in the range [−90, 90], being positive if rotated clockwise from the cross-myocyte direction when viewed 
	in the more circumferential direction, and negative if rotated counter-clockwise.
	Ferreira et al 2014 JCMR
	
	The plane normal to the E1 radial projection, called the mid fibre plane, can be found by the cross product of the E1 vector and the radial direction which gives the
	cross-myocyte direction.
		MidFibreVect = cross(E1Vect,RadVect)
	The E1 radial projection component of the E2 vector is removed to get the projection of the E2 vector onto the  mid fibre plane.
		E2Proj = E2Vect - E1RadProj*dot(E1RadProj,E2Vect)
		
Notes on dealing with vectors in Matlab
	Matlab generally uses a right-handed co-ordinate system when dealing with plotted data. However, when an image is shown it uses a left-handed co-ordinate system 
	which is annoying but things kind of still work normally with a few tricks.
	Everything below is treated as if the co-ordinate system is left-handed, annoying but deal with it.

	When showing an image i.e.
		fig = imshow(Trace{1}{1})
	A contour can then be plotted on top of the image i.e.
		hold on
		plot(epi(:,1),epi(:,2))

	When this is done the first dimension is the y-direction, vertical, and increases top to bottom.
	The second dimension is the x-direction, horizontal, and increases left to right.
	We will define the third dimension, the z-direction, as increasing out of the screen or as increasing from apex to base.