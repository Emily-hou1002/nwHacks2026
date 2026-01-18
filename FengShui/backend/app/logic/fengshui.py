"""
Feng Shui rule-based analysis logic
Implements priority rules: bed facing door, desk position, clutter, light, paths
"""
import math
from typing import List, Dict, Tuple
from app.models import AnalyzeRoomRequest, Object, Position, Suggestion, BaguaAnalysis


# Constants
MIN_WALKING_PATH_WIDTH = 0.6  # Minimum width for comfortable walking (meters)
CLUTTER_THRESHOLD = 0.5  # Room area coverage above which is considered cluttered (50%)
DOOR_ALIGNMENT_THRESHOLD = 45  # Degrees - bed/door alignment tolerance
COMMAND_POSITION_ANGLE = 120  # Degrees - ideal viewing angle for desk


def calculate_distance(pos1: Position, pos2: Position) -> float:
    """Calculate Euclidean distance between two positions"""
    return math.sqrt((pos1.x - pos2.x) ** 2 + (pos1.y - pos2.y) ** 2)


def calculate_object_area(obj: Object) -> float:
    """Calculate floor area covered by an object"""
    return obj.dimensions.length_m * obj.dimensions.width_m


def normalize_angle(angle: float) -> float:
    """Normalize angle to 0-360 range"""
    return angle % 360


def angle_difference(angle1: float, angle2: float) -> float:
    """Calculate the smallest difference between two angles"""
    diff = abs(angle1 - angle2) % 360
    return min(diff, 360 - diff)


class FengShuiAnalyzer:
    """Main analyzer for Feng Shui rules"""
    
    def __init__(self, request: AnalyzeRoomRequest):
        self.request = request
        self.room_area = request.room_dimensions.length_m * request.room_dimensions.width_m
        self.room_type = request.room_metadata.room_type.lower() if request.room_metadata.room_type else ""
        
        # Separate objects by type
        self.beds = [obj for obj in request.objects if obj.type.lower() == "bed"]
        self.desks = [obj for obj in request.objects if obj.type.lower() == "desk"]
        self.doors = [obj for obj in request.objects if obj.type.lower() == "door"]
        self.windows = [obj for obj in request.objects if obj.type.lower() == "window"]
        self.plants = [obj for obj in request.objects if obj.type.lower() == "plant"]
        
        self.suggestions: List[Suggestion] = []
        self.zone_scores: Dict[str, float] = {}
    
    # ==================== SUGGESTION HELPER METHODS ====================
    def _add_suggestion(self, id_str: str, title: str, description: str, 
                       severity: str, related_object_ids: List[str] = None):
        """Helper method to add suggestions with consistent formatting"""
        if related_object_ids is None:
            related_object_ids = []
        
        # Enhance description with context if available
        description = self._enhance_description_with_context(description)
        
        self.suggestions.append(Suggestion(
            id=id_str,
            title=title,
            description=description,
            severity=severity,
            related_object_ids=related_object_ids
        ))
    
    def _enhance_description_with_context(self, description: str) -> str:
        """Enhance description with room_style and intention context"""
        metadata = self.request.room_metadata
        enhancements = []
        
        if metadata.room_style:
            style_context = {
                "modern": "Consider sleek, minimalist solutions that maintain the modern aesthetic.",
                "minimalist": "Keep solutions simple and uncluttered to preserve the minimalist vibe.",
                "traditional": "Traditional Feng Shui principles work well with your decor style.",
                "zen": "This aligns with Zen philosophy - simplicity and natural flow.",
                "bohemian": "Bohemian style already embraces natural elements and flow.",
                "industrial": "Metal and wood elements can enhance energy in industrial spaces.",
                "contemporary": "Contemporary design can incorporate modern Feng Shui solutions.",
                "rustic": "Natural materials and earth tones support positive energy flow.",
                "luxury": "Luxury spaces benefit from attention to detail in energy flow."
            }
            if metadata.room_style.lower() in style_context:
                enhancements.append(style_context[metadata.room_style.lower()])
        
        if metadata.feng_shui_intention:
            intention_context = {
                "wealth": "This improvement supports your wealth intention and financial prosperity.",
                "career": "This change enhances your career zone and professional success.",
                "health": "This supports your health focus and overall wellbeing.",
                "love": "This improvement strengthens relationship energy in your space.",
                "balance": "This helps achieve the balance you're seeking.",
                "knowledge": "This supports your learning and wisdom goals.",
                "creativity": "This enhances creative energy flow in your space.",
                "family": "This improvement strengthens family connections and harmony.",
                "fame": "This supports recognition and reputation energy."
            }
            if metadata.feng_shui_intention.lower() in intention_context:
                enhancements.append(intention_context[metadata.feng_shui_intention.lower()])
        
        if enhancements:
            return description + " " + " ".join(enhancements)
        return description
    
    def analyze(self) -> Tuple[int, List[BaguaAnalysis], List[Suggestion], Dict[str, List[str]]]:
        """
        Main analysis method - returns (score, bagua_analysis, suggestions, ui_hints_dict)
        """
        # Run all rule checks based on room type
        if self.room_type == "bedroom":
            self._check_bed_facing_door()
        elif self.room_type == "office":
            self._check_desk_command_position()
        
        # Universal rules (apply to all rooms)
        self._check_clutter_density()
        self._check_natural_light()
        self._check_walking_paths()
        
        # Calculate zone scores
        self._calculate_bagua_scores()
        
        # Calculate overall score (weighted average)
        overall_score = self._calculate_overall_score()
        
        # Prepare UI hints
        highlight_objects = self._get_highlight_objects()
        recommended_zones = self._get_recommended_zones()
        
        return (overall_score, self._get_bagua_analysis_list(), self.suggestions, {
            "highlight_objects": highlight_objects,
            "recommended_zones": recommended_zones
        })
    
    # RULE 1: BED FACING DOOR (BEDROOM)
    def _check_bed_facing_door(self):
        """Check if bed is aligned with door - bad Feng Shui"""
        if not self.beds or not self.doors:
            return
        
        for bed in self.beds:
            bed_center = bed.position
            
            for door in self.doors:
                door_center = door.position
                distance = calculate_distance(bed_center, door_center)
                
                # Calculate angle from bed to door
                dx = door_center.x - bed_center.x
                dy = door_center.y - bed_center.y
                angle_to_door = math.degrees(math.atan2(dy, dx))
                if angle_to_door < 0:
                    angle_to_door += 360
                
                # Bed rotation determines orientation
                # A bed can be aligned with door if either head or foot faces the door
                bed_rotation = normalize_angle(bed.rotation_deg)
                
                # Bed has two directions: one at rotation, one at rotation+180
                bed_direction_1 = bed_rotation
                bed_direction_2 = (bed_rotation + 180) % 360
                
                # Check if either bed direction aligns with door direction (within threshold)
                # Also check if bed is aligned with opposite direction (door behind bed)
                diff_1 = angle_difference(bed_direction_1, angle_to_door)
                diff_2 = angle_difference(bed_direction_2, angle_to_door)
                diff_opposite_1 = angle_difference(bed_direction_1, (angle_to_door + 180) % 360)
                diff_opposite_2 = angle_difference(bed_direction_2, (angle_to_door + 180) % 360)
                
                # Bed is aligned if any direction matches door or door's opposite
                min_alignment_diff = min(diff_1, diff_2, diff_opposite_1, diff_opposite_2)
                
                if min_alignment_diff < DOOR_ALIGNMENT_THRESHOLD:
                    # Bad: bed is aligned with door
                    severity = "high" if distance < 3.0 else "medium"
                    
                    self._add_suggestion(
                        id_str=f"bed_door_alignment_{bed.id}",
                        title="Move bed away from door alignment",
                        description=f"Your bed is positioned in line with the door entrance, which disrupts energy flow and can reduce rest quality. Position your bed so it's not directly aligned with the door (ideally at a 45-degree angle or perpendicular).",
                        severity=severity,
                        related_object_ids=[bed.id, door.id]
                    )
                    
                    self.zone_scores["health"] = self.zone_scores.get("health", 75) - 25
                    self.zone_scores["love"] = self.zone_scores.get("love", 75) - 20
                    return
                elif min_alignment_diff > 60:
                    # Good: bed is well-positioned, not aligned with door
                    # Bonus for proper bed placement
                    self.zone_scores["health"] = self.zone_scores.get("health", 75) + 15
                    self.zone_scores["love"] = self.zone_scores.get("love", 75) + 10
                    
                    # Positive suggestion for good bed placement
                    self._add_suggestion(
                        id_str=f"bed_good_placement_{bed.id}",
                        title="Excellent bed placement",
                        description=f"Your bed is well-positioned away from the door entrance, which promotes restful sleep and positive energy flow. This placement supports health and relationship energy in your bedroom.",
                        severity="low",
                        related_object_ids=[bed.id]
                    )
    
    # RULE 2: DESK COMMAND POSITION (OFFICE) 
    def _check_desk_command_position(self):
        """Check if desk is in 'command position' - should face room, not wall"""
        if not self.desks or not self.doors:
            return
        
        for desk in self.desks:
            desk_center = desk.position
            
            # Find closest door (main entrance)
            closest_door = min(self.doors, key=lambda d: calculate_distance(desk_center, d.position))
            door_pos = closest_door.position
            
            # Calculate angle from desk to door
            dx = door_pos.x - desk_center.x
            dy = door_pos.y - desk_center.y
            angle_to_door = math.degrees(math.atan2(dy, dx))
            if angle_to_door < 0:
                angle_to_door += 360
            
            # Check if desk is facing the door/room (good) or facing wall (bad)
            # Rotation represents the direction the desk front is facing (where person sits)
            # Typically rotation 0° = facing right/east, 90° = facing up/north, 180° = west, 270° = south
            desk_rotation = normalize_angle(desk.rotation_deg)
            
            # The desk "facing" direction (where the person sits, front of desk) is the rotation
            desk_facing = desk_rotation
            
            # Calculate difference between desk facing direction and direction to door
            facing_diff = angle_difference(desk_facing, angle_to_door)
            
            # Desk is in command position if facing within ±60° of door direction
            # If facing >90° away from door, it's facing the wall (bad)
            if facing_diff > 90:  # Desk facing away from door (facing wall)
                self._add_suggestion(
                    id_str=f"desk_command_{desk.id}",
                    title="Reposition desk for command position",
                    description="Your desk is facing the wall instead of the room entrance. The 'command position' principle states that you should be able to see the door from your desk. This enhances focus, reduces stress, and supports career success.",
                    severity="high",
                    related_object_ids=[desk.id]
                )
                
                self.zone_scores["career"] = self.zone_scores.get("career", 75) - 30
                self.zone_scores["wealth"] = self.zone_scores.get("wealth", 75) - 15
            elif facing_diff < 60:  # Desk facing toward door (good position)
                # Good position - boost career zone significantly
                self.zone_scores["career"] = self.zone_scores.get("career", 75) + 20
                self.zone_scores["wealth"] = self.zone_scores.get("wealth", 75) + 10
                
                # Positive suggestion for good command position
                self._add_suggestion(
                    id_str=f"desk_good_command_{desk.id}",
                    title="Perfect command position",
                    description="Your desk is in the ideal 'command position' - you can see the door while working. This placement enhances focus, reduces stress, and supports career success and financial prosperity.",
                    severity="low",
                    related_object_ids=[desk.id]
                )
    
    # RULE 3: CLUTTER DENSITY 
    def _check_clutter_density(self):
        """Check if room is cluttered - too many objects in too little space"""
        if not self.request.objects:
            return
        
        # Calculate total area covered by furniture (excluding structural elements)
        structural_types = {"door", "window", "wall"}
        furniture_objects = [obj for obj in self.request.objects 
                           if obj.type.lower() not in structural_types]
        
        if not furniture_objects:
            return
        
        total_furniture_area = sum(calculate_object_area(obj) for obj in furniture_objects)
        coverage_ratio = total_furniture_area / self.room_area if self.room_area > 0 else 0
        
        if coverage_ratio > CLUTTER_THRESHOLD:
            severity = "high" if coverage_ratio > 0.75 else "medium"
            
            self._add_suggestion(
                id_str="clutter_density",
                title="Reduce clutter density",
                description=f"Your room has high furniture density ({coverage_ratio*100:.0f}% coverage). Clutter blocks energy flow (chi) and can create stress. Consider removing unnecessary items or reorganizing to create more open space.",
                severity=severity,
                related_object_ids=[]
            )
            
            # Penalty to all zones - more severe for high clutter
            penalty_multiplier = 20 if coverage_ratio > 0.75 else 15
            for zone in ["wealth", "health", "love", "career", "balance"]:
                self.zone_scores[zone] = self.zone_scores.get(zone, 75) - int(penalty_multiplier * coverage_ratio)
        elif coverage_ratio < 0.2:
            # Too empty - also not ideal (but less severe)
            self.zone_scores["balance"] = self.zone_scores.get("balance", 75) - 8
        elif 0.3 <= coverage_ratio <= 0.45:
            # Good balance - bonus for optimal spacing
            for zone in ["balance", "health"]:
                self.zone_scores[zone] = self.zone_scores.get(zone, 75) + 10
            
            # Positive suggestion for optimal clutter balance
            self._add_suggestion(
                id_str="clutter_optimal_balance",
                title="Well-organized space",
                description=f"Your room has an excellent balance of furniture and open space ({coverage_ratio*100:.0f}% coverage). This optimal density allows energy (chi) to flow freely while maintaining functionality. Keep this balance to support harmony and wellbeing.",
                severity="low",
                related_object_ids=[]
            )
    
    # RULE 4: NATURAL LIGHT ACCESS 
    def _check_natural_light(self):
        """Check window placement and obstructions for natural light"""
        if not self.windows:
            # No windows - negative impact
            self._add_suggestion(
                id_str="no_windows",
                title="Room lacks natural light",
                description="No windows detected in this room. Natural light is essential for positive energy (chi) flow. If possible, keep doors open during the day or use mirrors to reflect light from other rooms.",
                severity="medium",
                related_object_ids=[]
            )
            
            self.zone_scores["health"] = self.zone_scores.get("health", 75) - 25
            self.zone_scores["balance"] = self.zone_scores.get("balance", 75) - 20
            return
        
        # Check if windows are obstructed by large furniture
        for window in self.windows:
            window_pos = window.position
            
            # Find objects close to windows
            obstructing_objects = []
            for obj in self.request.objects:
                if obj.type.lower() in {"window", "door"}:
                    continue
                
                distance = calculate_distance(window_pos, obj.position)
                # If large object is very close to window, it might block light
                if distance < 1.0 and calculate_object_area(obj) > 0.5:
                    obstructing_objects.append(obj)
            
            if obstructing_objects:
                self._add_suggestion(
                    id_str=f"window_obstruction_{window.id}",
                    title="Clear space around windows",
                    description=f"Furniture is positioned too close to windows, blocking natural light. Move objects at least 1 meter away from windows to allow positive energy (chi) to flow freely into the room.",
                    severity="medium",
                    related_object_ids=[w.id for w in [window] + obstructing_objects[:3]]
                )
                
                self.zone_scores["health"] = self.zone_scores.get("health", 75) - 15
        
        # Having plants near windows is good - significant bonus
        windows_unobstructed = True
        for window in self.windows:
            window_pos = window.position
            obstructing = [
                obj for obj in self.request.objects
                if obj.type.lower() not in {"window", "door"}
                and calculate_distance(window_pos, obj.position) < 1.0
                and calculate_object_area(obj) > 0.5
            ]
            if obstructing:
                windows_unobstructed = False
                break
        
        if windows_unobstructed and self.windows:
            # Positive suggestion for unobstructed windows
            window_count_text = "multiple windows" if len(self.windows) >= 2 else "window"
            self._add_suggestion(
                id_str="natural_light_excellent",
                title="Excellent natural light access",
                description=f"Your room has {window_count_text} with clear, unobstructed access to natural light. This allows positive energy (chi) to flow freely, enhancing health and balance. Natural light supports circadian rhythms and overall wellbeing.",
                severity="low",
                related_object_ids=[w.id for w in self.windows[:3]]
            )
        
        if self.plants and self.windows:
            plant_window_proximity = any(
                calculate_distance(plant.position, window.position) < 2.0
                for plant in self.plants
                for window in self.windows
            )
            if plant_window_proximity:
                self.zone_scores["health"] = self.zone_scores.get("health", 75) + 15
                self.zone_scores["balance"] = self.zone_scores.get("balance", 75) + 15
                
                # Positive suggestion for plants near windows
                self._add_suggestion(
                    id_str="plants_near_windows",
                    title="Plants enhance natural light",
                    description="Your plants are positioned near windows, which amplifies positive energy flow. Plants near windows create a natural connection between indoor and outdoor energy, enhancing both health and balance zones.",
                    severity="low",
                    related_object_ids=[p.id for p in self.plants[:3]]
                )
        
        # Bonus for having multiple windows (good natural light)
        if len(self.windows) >= 2:
            self.zone_scores["health"] = self.zone_scores.get("health", 75) + 10
            self.zone_scores["balance"] = self.zone_scores.get("balance", 75) + 8
    
    # RULE 5: CLEAR WALKING PATHS 
    def _check_walking_paths(self):
        """Check if there are clear walking paths throughout the room"""
        if len(self.request.objects) < 2:
            return  # Need at least 2 objects to have paths between them
        
        # Check distances between objects (simple heuristic)
        # In a proper implementation, we'd do pathfinding, but for MVP this works
        min_path_width = MIN_WALKING_PATH_WIDTH
        
        # Check path from door to center of room
        if self.doors:
            door = self.doors[0]
            room_center = Position(
                x=self.request.room_dimensions.length_m / 2,
                y=self.request.room_dimensions.width_m / 2
            )
            
            # Find objects that might block the path from door to center
            # We check if objects are close to the direct line from door to center
            blocking_objects = []
            door_pos = door.position
            
            for obj in self.request.objects:
                if obj.type.lower() == "door":
                    continue
                
                obj_pos = obj.position
                door_to_center_dist = calculate_distance(door_pos, room_center)
                
                # Calculate distance from object to the line segment from door to center
                # Using perpendicular distance from point to line
                dx = room_center.x - door_pos.x
                dy = room_center.y - door_pos.y
                
                # If door and center are at same point, skip
                if door_to_center_dist < 0.1:
                    continue
                
                # Vector from door to object
                obj_dx = obj_pos.x - door_pos.x
                obj_dy = obj_pos.y - door_pos.y
                
                # Project object position onto door-center line
                t = (obj_dx * dx + obj_dy * dy) / (door_to_center_dist ** 2)
                t = max(0, min(1, t))  # Clamp to [0, 1] for line segment
                
                # Closest point on line segment to object
                closest_x = door_pos.x + t * dx
                closest_y = door_pos.y + t * dy
                closest_point = Position(x=closest_x, y=closest_y)
                
                # Distance from object to line
                dist_to_line = calculate_distance(obj_pos, closest_point)
                
                # Object is blocking if it's close to the line AND within the segment
                # Also consider object size
                obj_radius = max(obj.dimensions.length_m, obj.dimensions.width_m) / 2
                
                # Object blocks if distance to line is less than min_path_width/2 + object_radius
                if dist_to_line < (min_path_width / 2 + obj_radius) and 0.1 < t < 0.9:
                    blocking_objects.append(obj)
            
            if len(blocking_objects) >= 2:  # Changed from >2 to >=2
                self._add_suggestion(
                    id_str="walking_paths_blocked",
                    title="Clear walking paths",
                    description=f"Multiple objects are blocking clear pathways through the room. Maintain at least {min_path_width*100:.0f}cm clear space for walking paths to allow energy (chi) to flow freely. This reduces obstacles and promotes positive movement.",
                    severity="medium",
                    related_object_ids=[obj.id for obj in blocking_objects[:5]]
                )
                
                self.zone_scores["balance"] = self.zone_scores.get("balance", 75) - 20
                self.zone_scores["health"] = self.zone_scores.get("health", 75) - 10
            elif len(blocking_objects) == 0:
                # Good: clear paths throughout room
                self.zone_scores["balance"] = self.zone_scores.get("balance", 75) + 12
                self.zone_scores["health"] = self.zone_scores.get("health", 75) + 8
                
                # Positive suggestion for clear walking paths
                self._add_suggestion(
                    id_str="walking_paths_clear",
                    title="Clear pathways throughout room",
                    description=f"Your room has excellent clear pathways from the entrance to all areas. Maintain at least {min_path_width*100:.0f}cm clear space allows energy (chi) to flow freely, promoting movement and positive energy circulation. This supports balance and overall wellbeing.",
                    severity="low",
                    related_object_ids=[]
                )
    
    # BAGUA ZONE SCORING 
    def _calculate_bagua_scores(self):
        """Calculate scores for each Bagua zone based on room analysis"""
        # Initialize base scores
        base_scores = {
            "wealth": 70,
            "fame": 70,
            "love": 70,
            "health": 75,
            "creativity": 70,
            "knowledge": 70,
            "career": 70,
            "family": 70,
            "balance": 75
        }
        
        # Merge with calculated zone scores (which may have penalties)
        for zone in base_scores:
            if zone in self.zone_scores:
                base_scores[zone] = self.zone_scores[zone]
        
        # Apply room type bonuses - increased for better range
        if self.room_type == "bedroom":
            base_scores["love"] = base_scores.get("love", 70) + 8
            base_scores["health"] = base_scores.get("health", 75) + 8
        elif self.room_type == "office":
            base_scores["career"] = base_scores.get("career", 70) + 8
            base_scores["knowledge"] = base_scores.get("knowledge", 70) + 8
        elif self.room_type == "meditation room":
            base_scores["balance"] = base_scores.get("balance", 75) + 15
            base_scores["health"] = base_scores.get("health", 75) + 10
        
        # Boost intention zone if specified - increased bonus
        intention = self.request.room_metadata.feng_shui_intention
        if intention and intention in base_scores:
            base_scores[intention] = min(100, base_scores[intention] + 15)
        
        # Clamp scores to 0-100
        self.zone_scores = {zone: max(0, min(100, int(score))) 
                           for zone, score in base_scores.items()}
    
    def _get_bagua_analysis_list(self) -> List[BaguaAnalysis]:
        """Convert zone scores to BaguaAnalysis list"""
        zone_notes = {
            "wealth": "Wealth zone represents prosperity and abundance",
            "fame": "Fame zone relates to reputation and recognition",
            "love": "Love zone governs relationships and partnerships",
            "health": "Health zone affects physical and mental wellbeing",
            "creativity": "Creativity zone supports innovation and children",
            "knowledge": "Knowledge zone enhances learning and wisdom",
            "career": "Career zone influences professional success",
            "family": "Family zone impacts relationships with loved ones",
            "balance": "Balance zone promotes harmony and stability"
        }
        
        # Only include relevant zones (not all 9 for every response)
        relevant_zones = ["wealth", "health", "love", "career"]
        if self.request.room_metadata.feng_shui_intention:
            relevant_zones.append(self.request.room_metadata.feng_shui_intention)
        
        # Add balance for most rooms
        if self.room_type in ["meditation room", "bedroom"]:
            relevant_zones.append("balance")
        
        # Remove duplicates while preserving order
        seen = set()
        unique_zones = [z for z in relevant_zones if not (z in seen or seen.add(z))]
        
        return [
            BaguaAnalysis(
                zone=zone,
                score=self.zone_scores.get(zone, 70),
                notes=zone_notes.get(zone, f"{zone} zone analysis")
            )
            for zone in unique_zones
            if zone in self.zone_scores
        ]
    
    # OVERALL SCORING 
    def _calculate_overall_score(self) -> int:
        """Calculate overall Feng Shui score from zone scores"""
        if not self.zone_scores:
            return 75
        
        # Base weights - prioritize health and balance for general wellbeing
        base_weights = {
            "health": 1.5,
            "balance": 1.3,
            "wealth": 1.0,
            "love": 1.0,
            "career": 1.0,
            "knowledge": 0.8,
            "creativity": 0.8,
            "fame": 0.8,
            "family": 0.8
        }
        
        # If user specified a feng_shui_intention, heavily weight that zone
        intention = self.request.room_metadata.feng_shui_intention
        weights = base_weights.copy()
        
        if intention and intention in weights:
            # Boost intention zone weight significantly (2.5x base)
            # This makes the overall score reflect their priority
            weights[intention] = weights.get(intention, 1.0) * 2.5
        
        total_score = 0
        total_weight = 0
        
        for zone, score in self.zone_scores.items():
            weight = weights.get(zone, 1.0)
            total_score += score * weight
            total_weight += weight
        
        overall = int(total_score / total_weight) if total_weight > 0 else 75
        return max(0, min(100, overall))
    
    def _get_highlight_objects(self) -> List[str]:
        """Get object IDs that should be highlighted (problematic objects)"""
        highlight_ids = []
        for suggestion in self.suggestions:
            if suggestion.severity == "high" and suggestion.related_object_ids:
                highlight_ids.extend(suggestion.related_object_ids[:2])
        return list(set(highlight_ids))  # Remove duplicates
    
    def _get_recommended_zones(self) -> List[str]:
        """Get recommended zones based on intention and high scores"""
        zones = []
        
        # Add intention if specified
        if self.request.room_metadata.feng_shui_intention:
            zones.append(self.request.room_metadata.feng_shui_intention)
        
        # Add top 2 scoring zones
        sorted_zones = sorted(self.zone_scores.items(), key=lambda x: x[1], reverse=True)
        for zone, score in sorted_zones[:2]:
            if zone not in zones:
                zones.append(zone)
        
        return zones[:3]  # Max 3 zones
