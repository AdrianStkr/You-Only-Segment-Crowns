import argparse
import fiona
import glob
from os import listdir
from os.path import isfile, join
from shapely.geometry import shape

def parse_opt(known=False):
    parser = argparse.ArgumentParser()
    parser.add_argument('--imagepath', type=str, help='path to the images')
    parser.add_argument('--shapepath', type=str, help='path to the shapefiles(.shp) containing the object polygons')
    parser.add_argument('--outpath', type=str,
                        help='path to the out directory. Empty box and poly folders must be present in out directory')
    parser.add_argument('--imagesize', type=int, default=640,
                        help='define image size in px. Default 640')
    parser.add_argument('--attributes', type=bool, default=False,
                        help='Shall object-ID and object-class be saved? Only True if information is '
                             'present in attribute tables of shapefiles. Default False')

    return parser.parse_known_args()[0] if known else parser.parse_args()


def yolopolygons(IMAGEPATH, SHAPEPATH, OUTPATH, RASTERSIZE = 640, attributes = False):
    IMAGE_DIR = IMAGEPATH
    ANNOTATION_DIR = SHAPEPATH
    OUTPATH_POLY = OUTPATH + '/' + "poly"
    OUTPATH_BOXES = OUTPATH + '/' + "box"
    rastersize = RASTERSIZE

    rasterfiles = sorted([f for f in listdir(IMAGE_DIR) if isfile(join(IMAGE_DIR, f))],
                         key=lambda x: int(x.split('_')[1]))
    shapefiles = sorted(glob.glob(ANNOTATION_DIR + "/*.shp"), key=lambda x: int(x.split('_')[1]))

    # iterate through each image
    for index, image_filename in enumerate(rasterfiles):

        rastername = rasterfiles[index].split('_')

        raster_xmin = int(rastername[3]) / 1000
        raster_xmax = int(rastername[5]) / 1000
        raster_ymin = int(rastername[7]) / 1000
        raster_ymax = int(rastername[9]) / 1000

        shapefile = shapefiles[index]
        txtfile = str(OUTPATH_POLY) + "/" + rasterfiles[index].split('.')[0] + ".txt"
        boxfile = str(OUTPATH_BOXES) + "/" + rasterfiles[index].split('.')[0] + "_boxes_.txt"
        txt = open(txtfile, "w")
        box = open(boxfile, "w")
        with fiona.open(shapefile) as src:
            for f in src:
                bounds = shape(f['geometry']).bounds
                minx = int((bounds[0] - raster_xmin) / ((raster_xmax - raster_xmin) / rastersize)) / rastersize # Boundingbox x Y transform into Raster coordniatesystem
                maxy = int((bounds[3] - raster_ymax) / ((raster_ymax - raster_ymin) / rastersize)) / rastersize *-1
                maxx = int((bounds[2] - raster_xmin) / ((raster_xmax - raster_xmin) / rastersize)) / rastersize
                miny = int((bounds[1] - raster_ymax) / ((raster_ymax - raster_ymin) / rastersize)) / rastersize *-1
                if attributes == True:
                    properties = [f['properties']['treeID'], f['properties']['species_id']]
                    properties = ' '.join(str(x) for x in properties)
                    box.write(
                        "0 " + str(properties)+ " " + ' '.join([str(minx), str(miny), str(maxx), str(maxy)]) + "\n")
                else:
                    box.write("0 " + ' '.join([str(minx), str(miny), str(maxx), str(maxy)]) + "\n")
                out_linearRing = []
                for point in f['geometry']['coordinates'][0]:
                    x = ((point[0] - raster_xmin) / ((raster_xmax - raster_xmin) / rastersize))/rastersize
                    y = ((point[1] - raster_ymax) / ((raster_ymax - raster_ymin) / rastersize))/rastersize *-1
                    out_linearRing.append(x)
                    out_linearRing.append(y)
                out_linearRing = ' '.join(str(x) for x in out_linearRing)
                if attributes == True:
                    properties = [f['properties']['treeID'], f['properties']['species_id']]
                    properties = ' '.join(str(x) for x in properties)
                    txt.write(
                        "0 " + str(properties)+ " " + str(out_linearRing) + "\n")
                else:
                    txt.write(
                        "0 " + str(out_linearRing) + "\n")
            txt.close()
            box.close()


def main(opt):
    yolopolygons(opt.imagepath, opt.shapepath, opt.outpath, opt.imagesize, attributes=opt.attributes)

if __name__ == '__main__':
    opt = parse_opt()
    main(opt)
