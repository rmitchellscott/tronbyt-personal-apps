"""
Applet: Weather Station
Summary: Indoor/Outdoor sensors from Home Assistant
Description: Displays outdoor and indoor temperature and humidity from Home Assistant sensors
Author: Mitchell Scott
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

FONT_DEFAULT = "default"
DEFAULT_LABEL_FONT = "CG-pixel-4x5-mono"
DEFAULT_LABEL_FONT_2X = "terminus-14"
DEFAULT_VALUE_FONT = "CG-pixel-4x5-mono"
DEFAULT_VALUE_FONT_2X = "terminus-18-light"
DEFAULT_COL1_LABEL = "Outside"
DEFAULT_COL2_LABEL = "Inside"

def main(config):
    scale = 2 if canvas.is2x() else 1

    col1_sensor1 = fetch_sensor(config.get("col1_sensor1_entity"), config)
    col1_sensor2 = fetch_sensor(config.get("col1_sensor2_entity"), config)
    col2_sensor1 = fetch_sensor(config.get("col2_sensor1_entity"), config)
    col2_sensor2 = fetch_sensor(config.get("col2_sensor2_entity"), config)

    if col1_sensor1 == None or col1_sensor2 == None or col2_sensor1 == None or col2_sensor2 == None:
        return render.Root(
            child = render.Box(
                render.Text("Check sensor config", font = "tb-8", color = "#f00"),
            ),
        )

    col1_label = config.get("col1_label", DEFAULT_COL1_LABEL)
    col2_label = config.get("col2_label", DEFAULT_COL2_LABEL)

    label_font = config.get("label_font")
    if not label_font or label_font == FONT_DEFAULT:
        label_font = DEFAULT_LABEL_FONT_2X if scale == 2 else DEFAULT_LABEL_FONT

    value_font = config.get("value_font")
    if not value_font or value_font == FONT_DEFAULT:
        value_font = DEFAULT_VALUE_FONT_2X if scale == 2 else DEFAULT_VALUE_FONT

    return render.Root(
        child = render_weather_station(
            col1_label,
            col1_sensor1,
            col1_sensor2,
            col2_label,
            col2_sensor1,
            col2_sensor2,
            label_font,
            value_font,
            scale,
        ),
    )

def fetch_sensor(entity_id, config):
    if not entity_id or not config.get("ha_url") or not config.get("ha_token"):
        return None

    url = config.get("ha_url") + "/api/states/" + entity_id
    headers = {"Authorization": "Bearer " + config.get("ha_token")}

    rep = http.get(url, ttl_seconds = 60, headers = headers)
    if rep.status_code != 200:
        return None

    data = rep.json()
    state = data.get("state")
    if not state:
        return None

    isnum = (state.count(".") == 1 and state.replace(".", "").isdigit()) or state.isdigit()
    if not isnum:
        return None

    return float(state)

def render_weather_station(col1_label, col1_sensor1, col1_sensor2, col2_label, col2_sensor1, col2_sensor2, label_font, value_font, scale):
    DIVIDER_WIDTH = 1 * scale
    HEIGHT = 32 * scale

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        children = [
            render_column(col1_label, col1_sensor1, col1_sensor2, label_font, value_font, scale),
            render.Box(
                width = DIVIDER_WIDTH,
                height = HEIGHT,
                color = "#444",
            ),
            render_column(col2_label, col2_sensor1, col2_sensor2, label_font, value_font, scale),
        ],
    )

def render_column(label, sensor1, sensor2, label_font, value_font, scale):
    degree_symbol = "°" if scale == 2 else ""

    sensor1_rounded = math.round(sensor1 * 10) / 10
    sensor2_rounded = int(math.round(sensor2))

    return render.Column(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Text(
                label,
                font = label_font,
                color = "#FF0",
            ),
            render.Text(
                str(sensor1_rounded) + degree_symbol,
                font = value_font,
                color = "#FFF",
            ),
            render.Text(
                "%d%%" % sensor2_rounded,
                font = value_font,
                color = "#FFF",
            ),
        ],
    )

def get_schema():
    fonts = [
        schema.Option(display = "Default", value = FONT_DEFAULT),
    ]
    fonts.extend([
        schema.Option(display = key, value = value)
        for key, value in sorted(render.fonts.items())
    ])

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "Full URL to your Home Assistant instance (e.g., http://homeassistant.local:8123)",
                icon = "home",
            ),
            schema.Text(
                id = "ha_token",
                name = "Home Assistant Token",
                desc = "Long-lived access token from User Settings",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "col1_label",
                name = "Column 1 Label",
                desc = "Label for the first column (e.g., Outside, Left)",
                icon = "tag",
                default = DEFAULT_COL1_LABEL,
            ),
            schema.Text(
                id = "col2_label",
                name = "Column 2 Label",
                desc = "Label for the second column (e.g., Inside, Right)",
                icon = "tag",
                default = DEFAULT_COL2_LABEL,
            ),
            schema.Dropdown(
                id = "label_font",
                name = "Label Font",
                desc = "Font for column labels",
                icon = "font",
                options = fonts,
                default = FONT_DEFAULT,
            ),
            schema.Dropdown(
                id = "value_font",
                name = "Value Font",
                desc = "Font for sensor values",
                icon = "font",
                options = fonts,
                default = FONT_DEFAULT,
            ),
            schema.Text(
                id = "col1_sensor1_entity",
                name = "Column 1 Sensor 1",
                desc = "Entity ID for column 1, row 1 (e.g., sensor.outdoor_temperature)",
                icon = "gauge",
            ),
            schema.Text(
                id = "col1_sensor2_entity",
                name = "Column 1 Sensor 2",
                desc = "Entity ID for column 1, row 2 (e.g., sensor.outdoor_humidity)",
                icon = "gauge",
            ),
            schema.Text(
                id = "col2_sensor1_entity",
                name = "Column 2 Sensor 1",
                desc = "Entity ID for column 2, row 1 (e.g., sensor.indoor_temperature)",
                icon = "gauge",
            ),
            schema.Text(
                id = "col2_sensor2_entity",
                name = "Column 2 Sensor 2",
                desc = "Entity ID for column 2, row 2 (e.g., sensor.indoor_humidity)",
                icon = "gauge",
            ),
        ],
    )
