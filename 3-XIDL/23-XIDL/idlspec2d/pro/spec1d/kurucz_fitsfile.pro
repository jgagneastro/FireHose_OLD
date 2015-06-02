;+
; NAME:
;   kurucz_fitsfile
;
; PURPOSE:
;   Generate a single FITS file from a list of ASCII-formatted Kurucz models
;
; CALLING SEQUENCE:
;   kurucz_fitsfile, [ fileprefix, outfile ]
;
; INPUTS:
;
; OPTIONAL INPUTS:
;   fileprefix - Use all files in the current directory matching this string;
;                default to 'a*.spc'
;   outfile    - Name of output FIST file; default 'kurucz_stds_raw_v5.fits'
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The input ASCII files were generated by Christy Tremonti using
;   Kurucz' code.  The file name is assumed to encode the stellar
;   parameters of metallicity (FEH), effective temperature (TEFF)
;   and gravity (G).  For example, the file 'am05k2_5000_4.0.spc'
;   is interpreted to have FEH=-0.5, TEFF=5000, G=4.0.  I don't know
;   what the "k2" in the filename means.
;
;   HDU#0 of the output file has the fluxes.
;   HDU#1 of the output file is a FITS binary table with the stellar parameters.
;
; EXAMPLES:
;
; PROCEDURES CALLED:
;   mwrfits
;   sxpaddpar
;
; REVISION HISTORY:
;   18-Jan-2003  Written by D. Schlegel, Princeton
;-
;------------------------------------------------------------------------------
pro kurucz_fitsfile, fileprefix, outfile

   if (NOT keyword_set(fileprefix)) then fileprefix = 'a*.spc'
   if (NOT keyword_set(outfile)) then $
    outfile = 'kurucz_stds_raw_v5.fits'

   files = findfile(fileprefix, count=nfile)
   if (nfile EQ 0) then begin
      print, 'No input files found'
      return
   endif

   kindx = replicate( create_struct( $
    'MODEL', '', $
    'FEH'  , 0., $
    'TEFF' , 0., $
    'G'    , 0., $
    'MAG'  , fltarr(5)), nfile)

   for ifile=0L, nfile-1 do begin
      print, 'Reading file ', ifile+1, ' of ', nfile
      readcol, files[ifile], wave, flux, format='(D,F)'
      if (ifile EQ 0) then begin
         npix = n_elements(flux)
         allflux = fltarr(npix, nfile)
      endif
      allflux[*,ifile] = flux
      kindx[ifile].model = files[ifile]
      kindx[ifile].feh = 0.1 * float(strmid(files[ifile],2,2)) $
       * (strmid(files[ifile],1,1) EQ 'm' ? -1 : 1)
      kindx[ifile].teff = float(strmid(files[ifile],7,4))
      kindx[ifile].g = float(strmid(files[ifile],12,3))
   endfor

   hdr = ['']
   sxaddpar, hdr, 'CRVAL1', double(wave[0])
   sxaddpar, hdr, 'CD1_1', (wave[npix-1] - wave[0]) / (npix - 1)
   sxaddpar, hdr, 'CRPIX1', 1L
   sxaddpar, hdr, 'CTYPE1', 'LINEAR', ' Air wavelegnths [Ang]'

   mwrfits, allflux, outfile, hdr, /create
   mwrfits, kindx, outfile

   return
end
;------------------------------------------------------------------------------