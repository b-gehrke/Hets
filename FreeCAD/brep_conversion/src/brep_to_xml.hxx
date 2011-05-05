#ifndef __BREP_TO_XML_HXX
#define __BREP_TO_XML_HXX
#include <BRepTools.hxx>
#include <TopoDS_Shape.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <BRep_Builder.hxx>
#include <BRepTools_ShapeSet.hxx>
#include <Standard_TypeDef.hxx>
#include <Standard_Stream.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_CompSolid.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>
#include <TopoDS_Wire.hxx>
#include <vector>

class BrepToXML
{
private:
    TopoDS_Shape Sh;
    BRep_Builder builder;
    BRepTools_ShapeSet SS;
public:
    BrepToXML();
    BrepToXML(TopoDS_Shape);
    BrepToXML(const BrepToXML&);
    ~BrepToXML();
    void print_shape_type(void);
    bool read_brep(const char* filePath); //returns 1 if reading error occurs, 0 otherwise
    void print_subshapes(void);
    void print_location(void);
    TopoDS_Shape get_shape(void);
    void set_shape(TopoDS_Shape);
    std::vector <TopoDS_Shape> get_subshapes(void);
    void build_graph(void);
};
#endif
