cmake_minimum_required(VERSION 3.12)
project(vds2png LANGUAGES CXX)

find_package(openvds REQUIRED)
find_package(PNG REQUIRED)

add_executable(cppserver server.cpp)

target_link_libraries(cppserver  openvds::openvds)