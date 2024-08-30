### 2023 Adrian Straker & Stefano Puliti
### CC0 1.0 Universal 
### Run this R-Script to create pseudocolor images of canopy height models generated from 3D point clouds. 
### A detailed description of this image generation approach can be found in Straker et al. (2023): https://doi.org/10.1016/j.ophoto.2023.100045

### Arguments:
##  path: Character. Path to point cloud file directory.
##  thres_H: Integer. Height threshold (m). Points below are removed. Default = 2
##  out_dir: Path to out directory.
## image_size_px: Image size in pixel of the generated images. Default = 640
## res_image: Float. Spatial resolution CHM. Default = 0.2 
## form: Character. LAS Format. '.laz' for laz-files. '.las' for las-files. Default = '.las'

# get libraries
if (!require("rgdal")) install.packages("rgdal")
if (!require("lidR")) install.packages("lidR")
if (!require("RStoolbox")) install.packages("RStoolbox")
if (!require("viridis")) install.packages("viridis")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("raster")) install.packages("raster")

# set arguments
path <- 'path to laz files'
thres_H <- 2
out_dir <- 'path to out directory'
image_size_px <- 640
res_image <- 0.2
form <- '.las'


BEV_CHM=function (las=NULL
                  
                  ,thresh_H=2
                  
                  ,res_image=0.2
                  
                  ,out_dir=NULL
              
                  ,plot_id = NULL
                  
                  ,image_size_px=640){
  
  require(rgdal)
  
  require(lidR)
  
  require(RStoolbox)
  
  require(viridis)
  
  require(ggplot2)
  
  require(raster)
  
  
  ############################################################
  
  one_grid_las = las
  
  # remove noise
  
 one_grid_las = classify_noise(one_grid_las, ivf(5,20))
  
 one_grid_las = LAS(one_grid_las@data[one_grid_las@data$Classification<=5,])
  
  
  # normalize height
  
  one_grid_las= normalize_height(one_grid_las, tin())
  
  # compute CHM 
  
  #CHM= rasterize_canopy(one_grid_las, res=res_image, pitfree(max_edge = c(0, 1.5)))
  CHM= rasterize_canopy(one_grid_las, res=res_image, p2r())
  
  # select only values above 2 m and remove points above 45 m
  
  one_grid_las = lidR::filter_poi(one_grid_las, Z >= thresh_H)
  CHM[CHM>45]=0
  
  # normalize CHM
  
  CHM_n= normImage(CHM, norm=T)
  
  CHM_n= CHM_n+abs(cellStats(CHM_n, min))
  
  CHM_n=CHM_n/cellStats(CHM_n, max)*100
  
  # remove NA Values
  d_chm=CHM_n
  
  d_chm[is.na(d_chm)]=0
  
  # export plot
  
  name <- paste0(out_dir,"//_" , plot_id
                 
                 ,"_xminmm_",extent(d_chm)[1]*1000
                 
                 ,"_xmaxmm_",extent(d_chm)[2]*1000
                 
                 ,"_ymincm_",extent(d_chm)[3]*1000
                 
                 ,"_ymaxcm_",extent(d_chm)[4]*1000
                 
                 ,"_chm_.jpg")
  

  jpeg(filename = name,
       
       width = image_size_px, height = image_size_px, units = "px",
       
       pointsize = 12,
       
       quality = 75,
       
       bg = "white")

  
  # plot with ggplot
  
  d_chm_pts <- rasterToPoints(d_chm, spatial = TRUE)
  
  d_chm_df  <- data.frame(d_chm_pts)
  
  
  
  q=ggplot() +
    
    geom_raster(data = d_chm_df , aes(x = x, y = y, fill = Z)) +
    
    scale_fill_viridis_c(option = "inferno")+
    
    theme(plot.margin=unit(c(-0.05,-0.05,-0.05,-0.05), "null"),
          
          axis.title.x=element_blank(),
          
          axis.text.x=element_blank(),
          
          axis.ticks.x=element_blank(),
          
          axis.title.y=element_blank(),
          
          axis.text.y=element_blank(),
          
          axis.ticks.y=element_blank(),
          
          legend.position='none',
          
          panel.background = element_blank()
          
    )
  
  print(q)
  
  dev.off()
  
}

files <- list.files(path, pattern=form, all.files=FALSE,
                    full.names=TRUE)

# Process files
for (i in 1:length(files)){
  pc <- readLAS(files[i])
  split_name <- strsplit(files[i], '/')[[1]]
  name <- strsplit(split_name[length(split_name)], form)[[1]][1]
  BEV_CHM(las = pc, thresh_H = thres_H, res_image = res_image, out_dir = out_dir, plot_id = name, image_size_px = image_size_px)
}