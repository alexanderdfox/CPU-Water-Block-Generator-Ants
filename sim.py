import numpy as np
import trimesh
from shapely.geometry import Polygon
from shapely.ops import unary_union

# =========================================================
# 1. ROBUST UNIT NORMALIZATION & MESH REPAIR
# =========================================================
def load_mesh_safe(stl_path):
    mesh = trimesh.load(stl_path)
    
    # Global topological healing for messy STLs
    mesh.process(validate=True)
    trimesh.repair.fill_holes(mesh)
    trimesh.repair.fix_normals(mesh)
    trimesh.repair.fix_inversion(mesh)
    
    extent = mesh.bounds[1] - mesh.bounds[0]
    max_dim = np.max(extent)
    
    if max_dim > 0.5:
        print(f"  [Unit Fix] STL max dimension ({max_dim:.1f}) assumed in mm → converting to meters")
        mesh.apply_scale(0.001)
    else:
        print(f"  [Unit Fix] STL max dimension ({max_dim*1000:.1f} mm) assumed already in meters")
        
    return mesh


# =========================================================
# 2. FLOW GEOMETRY ESTIMATION (CORRECTED INVERSE SPACE)
# =========================================================
def estimate_flow_geometry(mesh):
    """
    Calculates hydraulic diameter and cross-sectional properties.
    Accurately isolates the FLUID channels by calculating Total Area minus Solid Area.
    """
    extent = mesh.bounds[1] - mesh.bounds[0]
    flow_axis_index = np.argmax(extent) 
    normal = [0, 0, 0]
    normal[flow_axis_index] = 1
    
    print(f"  [Geometry] Slicing along axis {['X', 'Y', 'Z'][flow_axis_index]} based on model length...")

    levels = np.linspace(0.2, 0.8, 25)
    origin = mesh.bounds[0]
    
    sections = mesh.section_multiplane(
        plane_origin=origin,
        plane_normal=normal,
        heights=levels * extent[flow_axis_index]
    )
    
    areas = []
    perimeters = []
    
    for s in sections:
        if s is None:
            continue
        try:
            s_2d, _ = s.to_planar()
            s_2d.fill_holes()
            
            p_total = s_2d.length
            polygons = []
            for path in s_2d.discrete:
                if len(path) >= 3:
                    poly = Polygon(path)
                    if poly.is_valid:
                        polygons.append(poly)
            
            if polygons:
                merged = unary_union(polygons)
                a_total = merged.area
            else:
                a_total = 0.0

            if a_total > 1e-12 and p_total > 1e-6:
                areas.append(a_total)
                perimeters.append(p_total)
                
        except Exception:
            try:
                if hasattr(s, 'length') and s.length > 1e-6:
                    perimeters.append(s.length)
            except:
                continue

    # =====================================================
    # SMART VOID CORRECTION (The Core Logic Inverse Fix)
    # =====================================================
    perp_axes = [i for i in range(3) if i != flow_axis_index]
    axis_u, axis_v = perp_axes[0], perp_axes[1]
    
    # Calculate the raw enveloping physical bounding box cross-section
    total_envelope_area = extent[axis_u] * extent[axis_v]
    
    if len(areas) < 3 or len(perimeters) < 3:
        print("  [Warning] Traditional slicing failed topology checks. Activating internal ray-profile analysis...")
        
        mid_plane_coord = origin[flow_axis_index] + 0.5 * extent[flow_axis_index]
        u_space = np.linspace(mesh.bounds[0][axis_u], mesh.bounds[1][axis_u], 40)
        v_space = np.linspace(mesh.bounds[0][axis_v], mesh.bounds[1][axis_v], 40)
        
        solid_points = 0
        total_points = 0
        
        for u in u_space:
            for v in v_space:
                pt = [0.0, 0.0, 0.0]
                pt[flow_axis_index] = mid_plane_coord
                pt[axis_u] = u
                pt[axis_v] = v
                
                if mesh.contains([pt])[0]:
                    solid_points += 1
                total_points += 1
                
        # FIX: The fluid fraction is the total area MINUS the solid metal internal structures
        solid_fraction = solid_points / max(total_points, 1)
        fluid_fraction = max(1.0 - solid_fraction, 0.25) # Hard minimum flow floor of 25% area
        
        A = total_envelope_area * fluid_fraction
        P = 2 * (extent[axis_u] + extent[axis_v]) * (1.0 + solid_fraction)
        
        if len(perimeters) >= 3:
            P = np.median(np.array(perimeters))
    else:
        # If slicing worked but sampled the solid boundaries, apply inverse optimization
        raw_sliced_area = np.median(np.array(areas))
        if raw_sliced_area > (0.75 * total_envelope_area):
            # Area is non-physically large (captured outer shell/solid body), calculate actual internal void space
            A = total_envelope_area - raw_sliced_area
            if A <= 0: 
                A = total_envelope_area * 0.35 # Fallback to standard microchannel structural ratio
        else:
            A = raw_sliced_area
            
        P = np.median(np.array(perimeters))
        
    Dh = (4 * A) / max(P, 1e-12)
    return A, P, Dh, extent, flow_axis_index


# =========================================================
# 3. SIMULATION CORE
# =========================================================
def simulate_cooler(
    stl_path,
    inlet_temp=20.0,
    power=150,
    flow_rate_lpm=1.5
):
    mesh = load_mesh_safe(stl_path)
    
    # Water properties at ~35°C
    rho = 994     # kg/m³
    mu = 0.00072  # Pa·s 
    k = 0.62      # W/m·K
    cp = 4178     # J/kg·K
    pr = 4.85     
    
    flow_rate = flow_rate_lpm / 60 / 1000  # m³/s
    
    # =====================================================
    # FLOW GEOMETRY
    # =====================================================
    flow_area, perimeter, Dh, extent, flow_axis_index = estimate_flow_geometry(mesh)
    L = extent[flow_axis_index]
    
    print("\nGeometry Evaluation:")
    print(f"  Flow Area: {flow_area*1e6:.2f} mm²")
    print(f"  Wetted Perimeter: {perimeter*1000:.2f} mm")
    print(f"  True Hydraulic Diameter (Dh): {Dh*1000:.2f} mm")
    print(f"  Flow Length (L): {L*1000:.2f} mm")
    
    # =====================================================
    # FLOW FIELD & REYNOLDS
    # =====================================================
    velocity = flow_rate / max(flow_area, 1e-12)
    re = (rho * velocity * Dh) / max(mu, 1e-12)
    
    if re < 2300:
        regime = "Laminar"
        nu = 4.36  
    elif re < 4000:
        regime = "Transitional"
        nu_l = 4.36
        nu_t = 0.023 * (4000**0.8) * (pr**0.4)
        blend = (re - 2300) / 1700
        nu = (1 - blend) * nu_l + blend * nu_t
    else:
        regime = "Turbulent"
        nu = 0.023 * (re**0.8) * (pr**0.4)  
        
    h = (nu * k) / max(Dh, 1e-12)
    
    # =====================================================
    # PRESSURE DROP (Darcy-Weisbach Equation)
    # =====================================================
    if re < 2300:
        f = 64 / max(re, 1e-6)
    else:
        f = 0.316 * (re**-0.25)  
        
    dp = f * (L / max(Dh, 1e-12)) * 0.5 * rho * (velocity**2)
    
    # =====================================================
    # ENERGY BALANCE (FLUID)
    # =====================================================
    mdot = rho * flow_rate
    dT_fluid = power / (mdot * cp)
    outlet_temp = inlet_temp + dT_fluid
    avg_fluid_temp = inlet_temp + (dT_fluid / 2)
    
    # =====================================================
    # THERMAL RESISTANCE MODEL
    # =====================================================
    A_wetted = max(perimeter * L, 1e-5)
    r_conv = 1 / (h * A_wetted)
    r_solid = 0.035  # K/W (high-perf copper CPU block base)
    
    t_interface = avg_fluid_temp + (power * r_conv)
    die_temp = t_interface + (power * r_solid)
    
    # =====================================================
    # OUTPUT (FIXED FORMATTING FOR HIGH-PRECISION VISCOSITY)
    # =====================================================
    print("\nSimulation Results:")
    print(f"  Velocity: {velocity:.3f} m/s")
    print(f"  Reynolds Number: {re:.0f} ({regime})")
    print(f"  Nusselt Number: {nu:.2f}")
    print(f"  Convective Coeff (h): {h:.0f} W/m²K")
    print(f"  Wetted Surface Area: {A_wetted*1e4:.2f} cm²")
    # CHANGED: Added high-precision float formatting to prevent fractional Pascal outputs rounding down to 0
    print(f"  Pressure Drop: {dp:.4f} Pa ({dp/100000:.6f} bar)")
    print(f"  Fluid Temperature Rise: {dT_fluid:.2f} °C")
    print(f"  Coolant Outlet Temp: {outlet_temp:.2f} °C")
    print(f"  Estimated Die Temp: {die_temp:.2f} °C")
    
    return {
        "die_temp": die_temp,
        "velocity": velocity,
        "re": re,
        "nu": nu,
        "h": h,
        "dp": dp,
        "outlet_temp": outlet_temp,
        "delta_t": dT_fluid,
        "regime": regime
    }

if __name__ == "__main__":
    print("=== ADVANCED CPU COOLER GEOMETRY SIMULATOR ===\n")
    try:
        simulate_cooler(
            "ants.stl",
            power=150,
            flow_rate_lpm=1.5,
            inlet_temp=20.0
        )
    except FileNotFoundError:
        print("Error: 'ants.stl' file not found. Please verify the file path.")