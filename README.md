
# ARKitNavigation
## App template to showcase the ability to create quite complex navigation systems in buildings using ARKit.

#### - Similar idea can be easily applied to SwiftUI
#### - Lidar equipped devices are appreciated for better occlusion



## Documentation
- The template consists of 2 tabs: first for map creation, second for usage.
- During creation process you are to create an ARWorldMap file that will be subsequently used as a base for the navigation.
- Basically the app creates an unweighted graph, which we will be searching through using a bfs (**Breadth-first search**) algorithm.
- There are 2 main types of anchors: "**path**" anchor and "**room**" anchor, where path represents anchors the user will be navigated through and room anchors represent your possible endpoints.
- The whole purpose of the creation tab is to thoroughly scan the area and add necessary anchors. 
- Regarding numbers near each path anchor: these numbers represent the number of adjacent path anchors that will be connected to this anchor (for filling neighbor nodes in future graph). It is made for easy and quick creation of such anchors without need of manual addition (the way how it will help is described below **->**)
**Example**: the beginning of the corridor should be marked as Path1 whereas intersections can be marked as Path3 or a combination of Path2 anchors.
- The "**Dist**" button is used to fill each already placed path anchor with its corresponding number of adjacent anchors (fills up a neighbor array for each path anchor via calculating distance **automatically**). This ensures correct graph creation without room for manual error.
- "**Room**" button has to be clicked after you specify its number in a simple textField. This will add our "endpoint" anchor which will automatically find its closest path anchor and connect itself to it. Thus it is a good idea to place a path anchor near each room to make future routes more perpendicular.
- "Save" button saves our created map in **.dat** format, which we will further load.
---
- The loading tab experience is much simpler) Firslty, you have to load the map you previously saved, then enter a right endpoint number(room) that you added there. After that the ARView will try its best to localize you in a saved map world.
- When the localization process completes successfully you will be presented with an arrowed route to your destination.

## Appendix

Have a good time playing around with it)

