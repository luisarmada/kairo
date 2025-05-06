shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;
uniform float shadow_offset : hint_range(0.0, 0.5) = 0.1; // Offset for shadow threshold
uniform float shadow_value : hint_range(0.0, 1.0) = 0.5; // Value below which shadows are quantized to value1
uniform float value_diff_threshold : hint_range(0.0, 0.2) = 0.05; // Minimum Value difference for texel lines
uniform float value1 : hint_range(0.0, 1.0) = 0.6;
uniform float value2 : hint_range(0.0, 1.0) = 1.0;
uniform float normal_threshold : hint_range(0.0, 1.0) = 0.1;
uniform float depth_threshold : hint_range(0.0, 1.0) = 0.05;
uniform float depth_artifact_correction_coef : hint_range(0.0, 5.0) = 2.0;
uniform vec3 outline_color : source_color = vec3(0.0);

// Sobel matrices for edge detection
const mat3 sobel_y = mat3(
    vec3(1.0, 0.0, -1.0),
    vec3(2.0, 0.0, -2.0),
    vec3(1.0, 0.0, -1.0)
);

const mat3 sobel_x = mat3(
    vec3(1.0, 2.0, 1.0),
    vec3(0.0, 0.0, 0.0),
    vec3(-1.0, -2.0, -1.0)
);

// Function to convert RGB to HSV
vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
    vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Function to convert HSV to RGB
vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Function to linearize depth
float get_depth(sampler2D depth_tex, vec2 uv, mat4 inv_projection_matrix) {
    float depth_raw = texture(depth_tex, uv).x;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depth_raw);
    vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float depth_linear = -view.z;
    return depth_linear;
}

// Function to compute normal-based edge value
float edge_value_normal(sampler2D normal_tex, vec2 uv, vec2 pixel_size, mat3 sobel) {
    float output = 0.0;
    vec3 normal = texture(normal_tex, uv).rgb;
    vec3 n = texture(normal_tex, uv + vec2(0.0, -pixel_size.y)).rgb;
    vec3 s = texture(normal_tex, uv + vec2(0.0, pixel_size.y)).rgb;
    vec3 e = texture(normal_tex, uv + vec2(pixel_size.x, 0.0)).rgb;
    vec3 w = texture(normal_tex, uv + vec2(-pixel_size.x, 0.0)).rgb;
    vec3 nw = texture(normal_tex, uv + vec2(-pixel_size.x, -pixel_size.y)).rgb;
    vec3 ne = texture(normal_tex, uv + vec2(pixel_size.x, -pixel_size.y)).rgb;
    vec3 sw = texture(normal_tex, uv + vec2(-pixel_size.x, pixel_size.y)).rgb;
    vec3 se = texture(normal_tex, uv + vec2(pixel_size.x, pixel_size.y)).rgb;

    mat3 error_mat = mat3(
        vec3(length(normal - nw), length(normal - n), length(normal - ne)),
        vec3(length(normal - w), 0.0, length(normal - e)),
        vec3(length(normal - sw), length(normal - s), length(normal - se))
    );

    output += dot(sobel[0], error_mat[0]);
    output += dot(sobel[1], error_mat[1]);
    output += dot(sobel[2], error_mat[2]);
    return abs(output);
}

// Function to compute depth-based edge value
float edge_value_depth(sampler2D depth_tex, vec2 uv, vec2 pixel_size, mat3 sobel, mat4 inv_projection_matrix) {
    float output = 0.0;
    float depth = get_depth(depth_tex, uv, inv_projection_matrix);
    float n = get_depth(depth_tex, uv + vec2(0.0, -pixel_size.y), inv_projection_matrix);
    float s = get_depth(depth_tex, uv + vec2(0.0, pixel_size.y), inv_projection_matrix);
    float e = get_depth(depth_tex, uv + vec2(pixel_size.x, 0.0), inv_projection_matrix);
    float w = get_depth(depth_tex, uv + vec2(-pixel_size.x, 0.0), inv_projection_matrix);
    float ne = get_depth(depth_tex, uv + vec2(pixel_size.x, -pixel_size.y), inv_projection_matrix);
    float nw = get_depth(depth_tex, uv + vec2(-pixel_size.x, -pixel_size.y), inv_projection_matrix);
    float se = get_depth(depth_tex, uv + vec2(pixel_size.x, pixel_size.y), inv_projection_matrix);
    float sw = get_depth(depth_tex, uv + vec2(-pixel_size.x, pixel_size.y), inv_projection_matrix);

    mat3 error_mat = mat3(
        vec3((depth - nw)/depth, (depth - n)/depth, (depth - ne)/depth),
        vec3((depth - w)/depth, 0.0, (depth - e)/depth),
        vec3((depth - sw)/depth, (depth - s)/depth, (depth - se)/depth)
    );

    output += dot(sobel[0], error_mat[0]);
    output += dot(sobel[1], error_mat[1]);
    output += dot(sobel[2], error_mat[2]);
    return abs(output);
}

// Function to compute local Value statistics (3x3 neighborhood)
float get_value_avg(sampler2D screen_tex, vec2 uv, vec2 pixel_size) {
    float sum_value = 0.0;
    int count = 0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * pixel_size;
            float value = rgb_to_hsv(texture(screen_tex, uv + offset).rgb).z;
            sum_value += value;
            count++;
        }
    }

    return sum_value / float(count);
}

// Function to determine the quantized Value level
float get_quantized_value(float value, float threshold) {
    float tolerance = 0.001;
    if (value < threshold - tolerance) {
        return value1;
    } else {
        return value2;
    }
}

void vertex() {
    POSITION = vec4(VERTEX.rg, 1.0, 1.0);
}

void fragment() {
    // Sample the screen texture
    vec4 c_texture = texture(SCREEN_TEXTURE, SCREEN_UV).rgba;

    // Sobel edge detection (for model edges, not ground shadows)
    vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
    float normal_edge = edge_value_normal(NORMAL_TEXTURE, SCREEN_UV, pixel_size, sobel_x) +
                        edge_value_normal(NORMAL_TEXTURE, SCREEN_UV, pixel_size, sobel_y);
    float depth_edge = edge_value_depth(DEPTH_TEXTURE, SCREEN_UV, pixel_size, sobel_x, INV_PROJECTION_MATRIX) +
                       edge_value_depth(DEPTH_TEXTURE, SCREEN_UV, pixel_size, sobel_y, INV_PROJECTION_MATRIX);

    // Adjust depth threshold with normal angle to reduce artifacts
    vec3 normal = texture(NORMAL_TEXTURE, SCREEN_UV).rgb;
    float angle = 1.0 - dot(normalize(normal - vec3(0.5)), vec3(0.0, 0.0, 1.0));
    float adjusted_depth_threshold = depth_threshold + angle * depth_artifact_correction_coef;

    // Check if pixel is part of a Sobel outline
    bool is_sobel_outline = normal_edge > normal_threshold || depth_edge > adjusted_depth_threshold;

    if (is_sobel_outline) {
        // Apply Sobel outline color
        ALBEDO = outline_color;
        ALPHA = 1.0;
    } else {
        // Convert to HSV
        vec3 hsv = rgb_to_hsv(c_texture.rgb);
        float hue = hsv.x;
        float saturation = hsv.y;
        float value = hsv.z;

        // Compute local Value average
        float avg_value = get_value_avg(SCREEN_TEXTURE, SCREEN_UV, pixel_size);

        // Select threshold
        float threshold = value < shadow_value ? avg_value + shadow_offset : avg_value;

        // Get the quantized Value for the current pixel
        float quantized_value = get_quantized_value(value, threshold);

        // Calculate texel size for 1-pixel offset
        vec2 texel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));

        // Sample neighboring pixels
        float value_left = rgb_to_hsv(texture(SCREEN_TEXTURE, SCREEN_UV - vec2(texel_size.x, 0.0)).rgb).z;
        float value_right = rgb_to_hsv(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(texel_size.x, 0.0)).rgb).z;
        float value_top = rgb_to_hsv(texture(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, texel_size.y)).rgb).z;
        float value_bottom = rgb_to_hsv(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, texel_size.y)).rgb).z;

        float avg_value_left = get_value_avg(SCREEN_TEXTURE, SCREEN_UV - vec2(texel_size.x, 0.0), pixel_size);
        float avg_value_right = get_value_avg(SCREEN_TEXTURE, SCREEN_UV + vec2(texel_size.x, 0.0), pixel_size);
        float avg_value_top = get_value_avg(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, texel_size.y), pixel_size);
        float avg_value_bottom = get_value_avg(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, texel_size.y), pixel_size);

        float threshold_left = value_left < shadow_value ? avg_value_left + shadow_offset : avg_value_left;
        float threshold_right = value_right < shadow_value ? avg_value_right + shadow_offset : avg_value_right;
        float threshold_top = value_top < shadow_value ? avg_value_top + shadow_offset : avg_value_top;
        float threshold_bottom = value_bottom < shadow_value ? avg_value_bottom + shadow_offset : avg_value_bottom;

        // Get quantized Values for neighbors
        float qvalue_left = get_quantized_value(value_left, threshold_left);
        float qvalue_right = get_quantized_value(value_right, threshold_right);
        float qvalue_top = get_quantized_value(value_top, threshold_top);
        float qvalue_bottom = get_quantized_value(value_bottom, threshold_bottom);

        // Check if Value difference is sufficient
        bool value_diff_left = abs(value - value_left) > value_diff_threshold;
        bool value_diff_right = abs(value - value_right) > value_diff_threshold;
        bool value_diff_top = abs(value - value_top) > value_diff_threshold;
        bool value_diff_bottom = abs(value - value_bottom) > value_diff_threshold;

        // Check if the current pixel is at a quantization boundary
        bool is_border = (quantized_value != qvalue_left && value_diff_left) ||
                         (quantized_value != qvalue_right && value_diff_right) ||
                         (quantized_value != qvalue_top && value_diff_top) ||
                         (quantized_value != qvalue_bottom && value_diff_bottom);

        // Output color
        if (is_border) {
            // Draw a black line at quantization boundaries
            ALBEDO = vec3(0.0);
            ALPHA = 1.0;
        } else {
            // Reconstruct the color with original Hue, Saturation, and quantized Value
            vec3 new_rgb = hsv_to_rgb(vec3(hue, saturation, quantized_value));
            ALBEDO = new_rgb;
            ALPHA = c_texture.a;
        }
    }
}