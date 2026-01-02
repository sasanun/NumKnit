from main import (
    SweaterDimensions,
    Metric,
    Gauge,
    SweaterType,
    Shape,
    Chart,
    XLSX
)

import numpy as np

data = SweaterDimensions(
    gauge=Gauge(metric=Metric.MM, vertical=24.5, horizontal=18.5),

    length_of_body=530, # 着丈
    length_of_shoulder_drop= 20, # 肩下がり
    length_of_ribbed_hem= 70, # 裾のゴム編み

    length_of_front_neck_drop = 75, # 前衿ぐりの深さ
    length_of_back_neck_drop = 20, # 後ろ衿ぐりの深さ

    width_of_body = 460, # 身幅
    width_of_neck = 160, # 襟ぐり幅

    length_of_sleeve = 510, # 袖丈
    length_of_ribbed_cuff = 70, # 袖口のゴム編みの長さ

    width_of_sleeve = 180, # 袖幅
    width_of_cuff = 110, # 袖口幅

    type=SweaterType.CREW_NECK_SWEATER,

    is_odd=True
)

front_body_shape = Shape.front_body_from(data)
back_body_shape = Shape.back_body_from(data)
sleeve_shape = Shape.sleeve_from(data)

shapes = {
    "front_body": front_body_shape,
    "back_body": back_body_shape,
    "sleeve": sleeve_shape,
}

# SVGを描画する際の属性値
attribute={
    'fill': "white",
    'stroke': "black",
    'stroke-width': 1}

# SVGファイルを書き出す
for name, shape in shapes.items():
    shape.write_svg(filename=f"output/{name}.svg", attributes=[attribute])

# チャートを生成する
front_body_chart = Chart.from_shape(front_body_shape)
back_body_chart = Chart.from_shape(back_body_shape) 
sleeve_chart = Chart.from_shape(sleeve_shape)

# チャートの調整
charts = {
    "front_body": front_body_chart, 
    "back_body": back_body_chart, 
    "sleeve": sleeve_chart,
}

for name, chart in charts.items():
    # チャートをCSVファイルとして書き出す
    chart.write_csv(filename=f"output/{name}.csv")

XLSX.from_charts(charts).save(filename="output/output.xlsx")