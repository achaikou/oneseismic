#include <png.h>
#include <iostream>
#include <sstream>
#include <map>
#include <chrono>
#include <cstdlib>
#include <fstream>


#include <OpenVDS/IJKCoordinateTransformer.h>
#include <OpenVDS/OpenVDS.h>

using namespace std;

string tmpPath="/tmp/";



vector<float> data;
int sliceW ;
int sliceH ;
int width=600;
int height=800;

float minS;
float maxS;



void getData(std::string url, std::string connectionString, int dimension,int slice)
{
  
  OpenVDS::Error error;
  OpenVDS::VDSHandle handle = OpenVDS::Open(url, connectionString, error);
  
  if(error.code != 0)
    {
      std::cerr << "Could not open VDS: " << error.string << std::endl;
      exit(1);
    }
  
  OpenVDS::VolumeDataAccessManager accessManager = OpenVDS::GetAccessManager(handle);
  OpenVDS::VolumeDataLayout const *layout = accessManager.GetVolumeDataLayout();
  
  int voxelMin[OpenVDS::Dimensionality_Max] = { 0, 0, 0, 0, 0, 0};
  int voxelMax[OpenVDS::Dimensionality_Max] = { 1, 1, 1, 1, 1, 1};
  
  voxelMin[0] = 0;
  voxelMax[0] = layout->GetDimensionNumSamples(0);
  voxelMin[1] = 0;
  voxelMax[1] = layout->GetDimensionNumSamples(1);
  voxelMin[2] = 0;
  voxelMax[2] = layout->GetDimensionNumSamples(2);
  


  voxelMin[dimension] = slice;
  voxelMax[dimension] = slice+1;
  
  switch (dimension) {
  case 0:
    sliceH = layout->GetDimensionNumSamples(1);
    sliceW = layout->GetDimensionNumSamples(2);
    break;
  case 1:
    sliceH = layout->GetDimensionNumSamples(0);
    sliceW = layout->GetDimensionNumSamples(2);
    break;
  case 2:
    sliceH = layout->GetDimensionNumSamples(0);
    sliceW = layout->GetDimensionNumSamples(1);
      break;
  }
  
  auto request = accessManager.RequestVolumeSubset<float>(OpenVDS::Dimensions_012, 0, 0, voxelMin, voxelMax);
  data = std::move(request->Data());
}

int main() {
  std::string url(std::getenv("URL"));
  std::string connection_string(std::getenv("CONNECTION_STRING"));
  int dimension = std::stoi(std::getenv("DIMENSION"));
  int index = std::stoi(std::getenv("INDEX"));
  getData(url, connection_string,dimension,index);
}