;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; remap 1k to icom MPAS: TOPO, SOIL ;;;;;;;;;;
if False then
    vars_soil = (/"PCT_SAND", "PCT_CLAY", "ORGANIC"/)
    vars_topo = (/"TOPO", "STD_ELEV", "STDEV_ELEV","TERRAIN_CONFIG", \
                  "SINSL_SINAS","SINSL_COSAS","SLOPE","SKY_VIEW"/)
    ;; merge the soil and topo variables
    vars0 = venn2_union(vars_soil, vars_topo)
    fil_in = "/compyfs/lili400/project/ICoM/data/elm_5h/surfdata_conus_1k_icom.nc"
    system("/bin/mkdir -p " + dir_ot)
    map_method = "conserve" ; "bilinear"  ; neareststod; default; neareststod; nearestdtos

    ;;;; MASK files for soil and topo ;;; 
    if False then 
      f1 = addfile(fil_in,"r")

      ;;; soil ;;;;;
      if False then 
        vari = "PCT_SAND"
        tmp0 := f1->$vari$
        printVarSummary(tmp0)
        printMinMax(tmp0,0)

        mask1 = where(tmp0(0,:,:).ge.0 .and. tmp0(0,:,:).le. 100, 1 ,0)
        copy_VarMeta(tmp0(0,:,:), mask1)

        printMinMax(mask1,0)
        printVarSummary(mask1)
        print( get_unique_values(mask1) )

        fout = dir_ot +"mask_1k_soil.nc"
        system("/bin/rm -f " + fout)
        print("  Out: " + fout)
        fo := addfile(fout, "c")
        fo@creation_data=systemfunc("date")
        fo@information="Mapped file from 5hm --> MPAS, Created by Lingcheng LI"
        fo->mask = mask1
        exit 
      end if 

      ;;; the mask for TOPO
      if False then 
        vari = "TOPO"
        tmp0 := f1->$vari$
        printVarSummary(tmp0)
        printMinMax(tmp0,0)

        mask1 = where(tmp0.ge.0, 1 ,0)
        copy_VarMeta(tmp0, mask1)

        printMinMax(mask1,0)
        printVarSummary(mask1)
        print( get_unique_values(mask1) )

        fout = dir_ot +"mask_1k_topo.nc"
        system("/bin/rm -f " + fout)
        print("  Out: " + fout)
        fo := addfile(fout, "c")
        fo@creation_data=systemfunc("date")
        fo@information="Mapped file from 5hm --> MPAS, Created by Lingcheng LI"
        fo->mask = mask1
        
        exit 
      end if 

    end if 

    ;;;; MAP and Weight files for soil and topo ;;; 
    if False then 
      f1 = addfile(fil_in,"r")
      ;;; SOIL ;;;;;
      if True then 
        srcGridName = dir_ot + "src_SCRIP_icom_1k_SOIL.nc"
        dstGridName = "../dst_SCRIP_ROF_MPAS_ICoM.nc"
        wgtFileName = dir_ot + "map_WEGHT_icom_1k_mpas_SOIL_"+map_method+".nc"

        f3 = addfile(dir_ot +"mask_1k_soil.nc","r")
        mask1 = f3->mask
        printVarSummary(mask1)

        vari = "PCT_SAND"
        tmp0 := f1->$vari$
        printVarSummary(tmp0)
        printMinMax(tmp0,0)

        print(">>>>>>>> Generate SCRIPT <<<<<<<<")
        Opt                = True
        Opt@ForceOverwrite = True
        Opt@PrintTimings   = True
        Opt@GridMask = mask1
        rectilinear_to_SCRIP(srcGridName,tmp0&lsmlat,tmp0&lsmlon,Opt)
        delete(Opt)

        ;; Generate the weights (mapping)
        print(">>>>>>>> Generate Mapping <<<<<<<<")
        Opt                      = True
        Opt@InterpMethod         = map_method ; "bilinear"  ; default
        Opt@ForceOverwrite       = True
        Opt@PrintTimings         = True
        ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)
        ; syscmd = "ESMF_RegridWeightGen -m conserve --ignore_unmapped -s " + srcGridName +" -d "+dstGridName+ " -w "+wgtFileName
        ; print(syscmd)
        ; system(syscmd)
        delete(Opt)
      end if 

      ;;; TOPO ;;;;;
      if True then 
        srcGridName = dir_ot + "src_SCRIP_icom_1k_TOPO.nc"
        dstGridName = "../dst_SCRIP_ROF_MPAS_ICoM.nc"
        wgtFileName = dir_ot + "map_WEGHT_icom_1k_mpas_TOPO_"+map_method+".nc"

        f3 = addfile(dir_ot +"mask_1k_topo.nc","r")
        mask1 = f3->mask
        printVarSummary(mask1)

        vari = "TOPO"
        tmp0 := f1->$vari$
        printVarSummary(tmp0)
        printMinMax(tmp0,0)

        print(">>>>>>>> Generate SCRIPT <<<<<<<<")
        Opt                = True
        Opt@ForceOverwrite = True
        Opt@PrintTimings   = True
        Opt@GridMask = mask1
        rectilinear_to_SCRIP(srcGridName,tmp0&lsmlat,tmp0&lsmlon,Opt)
        delete(Opt)

        ;; Generate the weights (mapping)
        print(">>>>>>>> Generate Mapping <<<<<<<<")
        Opt                      = True
        Opt@InterpMethod         = map_method; "conserve" ; "bilinear"  ; default
        Opt@ForceOverwrite       = True
        Opt@PrintTimings         = True
        ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)
        ; syscmd = "ESMF_RegridWeightGen -m conserve --ignore_unmapped -s " + srcGridName +" -d "+dstGridName+ " -w "+wgtFileName
        ; print(syscmd)
        ; system(syscmd)
        delete(Opt)

      end if 
      ; exit
    end if 

    ;;;; remap the soil and topo variables ;;;
    if True then 
      fout = dir_ot + "Soil_Topo_icom_1k_2_mpas_"+map_method+".nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="Mapped file from 5hm --> MPAS, Created by Lingcheng LI"
      print(""+vars0)
      
      do vi = 0, dimsizes(vars0) - 1
          print(">>>>>>>> "+vars0(vi)+" <<<<<<<< ") 

          vari = vars0(vi)

          f1 = addfile(fil_in,"r")
          tmp0 := f1->$vari$
          tmp0@_FillValue = -9999.
          printVarSummary(tmp0)
          printMinMax(tmp0,0)
          print("Mean: " + avg(tmp0) )


          ;;; input weight file 
          ;;; soil files
          if any(vars_soil.eq.vari) then
            wgtFileName = dir_ot + "map_WEGHT_icom_1k_mpas_SOIL_"+map_method+".nc"
          end if
          ;;; topo files
          if any(vars_topo.eq.vari) then
            wgtFileName = dir_ot + "map_WEGHT_icom_1k_mpas_TOPO_"+map_method+".nc"
          end if 

          ;; Generate the dist file
          ;---In V6.1.0, coordinates and attributes are copied automatically
          Opt                = True
          Opt@PrintTimings   = True
          tmp1 := ESMF_regrid_with_weights(tmp0,wgtFileName,Opt)
          delete(Opt)

          sz_tmp1 := num(dimsizes(tmp1))
          tmp1!(sz_tmp1-1) = "gridcell"
          delete_VarAtts(tmp1,(/"lon1d","lat1d"/))
          printVarSummary(tmp1)
          printMinMax(tmp1,0)
          print("Mean: " + avg(tmp1) )

          fo->$vari$ = tmp1
      end do ; var 
      exit 
    end if 
    
  exit
end if
