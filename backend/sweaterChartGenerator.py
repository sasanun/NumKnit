# ============================
# 標準ライブラリ
# ============================
import os                                # 
import tempfile                          # 一時ファイル
import re                                # 正規表現
import math                              # 数学関数
import numpy as np                       # 数値処理
from operator import index               # インデックス操作関連
from xml.etree import ElementTree        # XML/SVG の DOM 解析
import logging                           # ログ
import asyncio                           # 非同期処理
from enum import Enum                    # 列挙型

# ============================
# サードパーティライブラリ
# ============================
from pydantic import (                    # Pydantic Model
    BaseModel,
    Field,
    computed_field,
    model_validator
)
from pydantic_core import(                # Pydantic の検証エラー
    PydanticCustomError, ValidationError
)
from svgpathtools import (                # SVG パス解析ツール
    parse_path,
    Path,
    Line,
    CubicBezier,
    QuadraticBezier,
)
from shapely.geometry import (            # 形状処理（点・多角形）
    Point,
    Polygon
)
from shapely.ops import unary_union       # ジオメトリ結合
from fastapi import(                      # FastAPI
    FastAPI,
    Request,
    HTTPException,
    BackgroundTasks,
)
from fastapi.responses import(
    FileResponse,
    JSONResponse,
)

# ロガーの初期化
logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

logger = logging.getLogger()
logger.setLevel(logging.DEBUG) # TODO 後でメイン関数に移すよ

# FastAPI の初期化
app = FastAPI(title="Sweater Chart Generator")

# SVGを描画する際のパラメータ
fill, stroke, stroke_width = "white", "black", 1

class Symbol(Enum):
    # 名前 = (番号, 記号)
    NONE     = (0, "#")
    KNIT     = (1, "")
    PURL     = (2, "-")
    CAST_OFF = (3, "●")
    K2TOG    = (4, "＼")
    SSK      = (5, "／")
    K1B      = (6, "∨")

    def __init__(self, number, char):
        self.number = number
        self.char = char

    @classmethod
    def from_number(cls, num):
        for item in cls:
            if item.number == num:
                return item
        return cls.NONE

# セーターの形状のEnum
class BodyShapeType(str, Enum):
    STANDARD = "standard"
    # CARDIGAN = "cardigan"
    # VEST = "vest"
    

class NeckShapeType(str, Enum):
    CREW_NECK = "crew-Neck"
    # V_NECK = "v-neck"
    # TURTLENECK = "turtleneck"

class ShoulderShapeType(str, Enum):
    STANDARD = "standard"
    # BOX = "box"
    # RAGLAN = "raglan"

class Side(str, Enum):
    RIGHT = "right"
    LEFT = "left"

# POSTで受け取るデータを表現するクラス Pydantic Model
class SweaterDimensions(BaseModel):
    """
    長袖のセーターの寸法とゲージを定義するデータモデル
    """
    gauge_height: float = Field(..., description="ゲージの段数", gt=0)
    gauge_width: float = Field(..., description="ゲージの目数", gt=0)

    length_of_body: float = Field(..., description="着丈", gt=0)
    length_of_shoulder_drop: float = Field(..., description="肩下がり", gt=0)
    length_of_ribbed_hem: float = Field(..., description="裾ゴム編み", gt=0)

    length_of_front_neck_drop: float = Field(..., description="前襟ぐり下がり", gt=0)
    length_of_back_neck_drop: float = Field(..., description="後ろ襟ぐり下がり", gt=0)

    width_of_body: float = Field(..., description="身幅", gt=0)
    width_of_neck: float = Field(..., description="襟ぐり幅", gt=0)
    length_of_sleeve: float = Field(..., description="袖丈", gt=0)
    length_of_ribbed_cuff: float = Field(..., description="袖口ゴム編み", gt=0)

    width_of_sleeve: float = Field(..., description="袖幅", gt=0)
    width_of_cuff: float = Field(..., description="袖口幅", gt=0)

    body_shape_type: BodyShapeType = Field(..., description="身頃の形状")
    neck_shape_type: NeckShapeType = Field(..., description="襟の形状")
    shoulder_shape_type: ShoulderShapeType = Field(..., description="肩の形状")

    is_odd: bool = Field(..., description="水平方向の目数を奇数にする")

    def __str__(self) -> str:
        lines = [
            f"SweaterDimensions:",
            f"gauge_height: {self.gauge_height}",
            f"gauge_width: {self.gauge_width}",
            "",
            f"length_of_body: {self.length_of_body}",
            f"length_of_shoulder_drop: {self.length_of_shoulder_drop}",
            f"length_of_ribbed_hem: {self.length_of_ribbed_hem}",
            f"length_of_front_neck_drop: {self.length_of_front_neck_drop}",
            f"length_of_back_neck_drop: {self.length_of_back_neck_drop}",
            "",
            f"width_of_body: {self.width_of_body}",
            f"width_of_neck: {self.width_of_neck}",
            "",
            f"length_of_sleeve: {self.length_of_sleeve}",
            f"length_of_ribbed_cuff: {self.length_of_ribbed_cuff}",
            "",
            f"width_of_sleeve: {self.width_of_sleeve}",
            f"width_of_cuff: {self.width_of_cuff}",
            "",
            f"body_shape_type: {self.body_shape_type}",
            f"neck_shape_type: {self.neck_shape_type}",
            f"shoulder_shape_type: {self.shoulder_shape_type}",
            "",
            f"is_odd: {self.is_odd}",
            "",
            f"stitch_width: {self.stitch_width}",
            f"stitch_length: {self.stitch_length}",
            "",
            f"length_of_body_side: {self.length_of_body_side}",
            f"length_of_vertical_armhole: {self.length_of_vertical_armhole}",
            "",
            f"width_of_horizontal_armhole: {self.width_of_horizontal_armhole}",
            f"width_of_shoulder: {self.width_of_shoulder}",
            "",
            f"length_of_sleeve_cap: {self.length_of_sleeve_cap}",
            f"length_of_sleeve_side: {self.length_of_sleeve_side}"
        ]
        return "\n".join(lines)

    @computed_field
    @property
    def stitch_width(self) -> float:
        """ ゲージから1目の幅"""
        return math.ceil(100000 / self.gauge_width) / 1000

    @computed_field
    @property
    def stitch_length(self) -> float:
        """ ゲージから1目の高さ"""
        return math.ceil(100000 / self.gauge_height) / 1000

    @computed_field
    @property
    def length_of_body_side(self) -> float:
        """ 脇下から裾のゴム編みの上端までの長さ"""
        return self.length_of_body - self.length_of_shoulder_drop - self.length_of_vertical_armhole - self.length_of_ribbed_hem

    @computed_field
    @property
    def length_of_vertical_armhole(self) -> float:
        """ 袖ぐりの垂直方向の長さ """
        return int(self.width_of_sleeve / self.stitch_length) * self.stitch_length

    @computed_field
    @property
    def width_of_horizontal_armhole(self) -> float:
        """ 袖ぐりの水平方向の長さ 身幅の1/10"""
        return int((self.width_of_body * 0.1) / self.stitch_width) * self.stitch_width

    @computed_field
    @property
    def width_of_shoulder(self) -> float:
        """ 肩幅(mm) 身幅から袖ぐりの水平方向と襟ぐり幅を引いた長さの1/2"""
        return (self.width_of_body - self.width_of_horizontal_armhole * 2 - self.width_of_neck) / 2

    @computed_field
    @property
    def length_of_sleeve_cap(self) -> float:
        """ 袖山の高さ(mm) 袖ぐりの水平方向の長さの2倍"""
        return int((self.width_of_horizontal_armhole * 2) / self.stitch_length) * self.stitch_length

    @computed_field
    @property
    def length_of_sleeve_side(self) -> float:
        """ 袖下(mm)　袖丈から袖山の高さ・袖口のゴム編みを引いた長さ"""
        return self.length_of_sleeve - self.length_of_sleeve_cap - self.length_of_ribbed_cuff

    def _round_to_multiple_stitch_length(self, value) -> float:
        """ 寸法を stitch_length の整数倍に丸める"""
        return int(value / self.stitch_length) * self.stitch_length

    def _round_to_multiple_stitch_width(self, value) -> float:
        """ 寸法を stitch_width の整数倍に丸める"""
        return int(value / self.stitch_width) * self.stitch_width

    def _round_to_multiple_odd_or_even_stitch_width(self, value) -> float:
        """ 寸法を stitch_width の奇数倍または偶数倍に丸める"""
        if self.is_odd:
            return int(value / self.stitch_width / 2) * 2 * self.stitch_width + self.stitch_width
        else:
            return int(value / self.stitch_width / 2) * 2 * self.stitch_width

    def _round_to_multiple_odd_or_even_stitch_width_half(self, value) -> float:
        """ 寸法を stitch_width の(整数+1/2)倍または整数倍に丸める"""
        if self.is_odd:
            return self._round_to_multiple_stitch_width(value) + self.stitch_width / 2
        else:
            return self._round_to_multiple_stitch_width(value)

    @model_validator(mode='after')
    def _adjust_and_check_dimensions(self) -> 'SweaterDimensions':
        """寸法の調整と検証を行う"""
        
        # 編目の縦の長さの整数倍に丸めた着丈
        self.length_of_body = self._round_to_multiple_stitch_length(self.length_of_body)

        # 編目の縦の長さの整数倍に丸めた肩下がり
        self.length_of_shoulder_drop = self._round_to_multiple_stitch_length(self.length_of_shoulder_drop)

        # 編目の縦の長さの整数倍に丸めた裾のゴム編み
        self.length_of_ribbed_hem = self._round_to_multiple_stitch_length(self.length_of_ribbed_hem)

        # 編目の縦の長さの整数倍に丸めた前襟ぐり下がり
        self.length_of_front_neck_drop = self._round_to_multiple_stitch_length(self.length_of_front_neck_drop)

        # 編目の縦の長さの整数倍に丸めた後襟ぐり下がり
        self.length_of_back_neck_drop = self._round_to_multiple_stitch_length(self.length_of_back_neck_drop)

        # 編目の横の長さの奇数倍または偶数倍に丸めた身幅
        self.width_of_body = self._round_to_multiple_odd_or_even_stitch_width(self.width_of_body)

        # 編目の横の長さの半分の奇数倍または偶数倍に丸めた襟幅
        self.width_of_neck = self._round_to_multiple_odd_or_even_stitch_width(self.width_of_neck)

        # 編目の縦の長さの整数倍に丸めた袖丈
        self.length_of_sleeve = self._round_to_multiple_stitch_length(self.length_of_sleeve)

        # 編目の縦の長さの整数倍に丸めた袖口のゴム編み
        self.length_of_ribbed_cuff = self._round_to_multiple_stitch_length(self.length_of_ribbed_cuff)

        # 編目の横の長さの半分の奇数倍または偶数倍に丸めた袖幅
        self.width_of_sleeve = self._round_to_multiple_odd_or_even_stitch_width_half(self.width_of_sleeve)

        # 編目の横の長さの半分の奇数倍または偶数倍に丸めた袖口幅
        self.width_of_cuff = self._round_to_multiple_odd_or_even_stitch_width_half(self.width_of_cuff)

        # TODO 寸法値の検証
        if False:
            raise PydanticCustomError(
                'value_error', # エラータイプ
                'エラーの理由',
                {'min_length': 0} # JSONに出力したい追加情報
            )

        logger.info(f"SweaterDimensions is initialized.")
        logger.debug(self)
        return self

# 検証エラーを捕捉するための例外ハンドラー
@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    """
    検証エラーが発生した場合に実行されるハンドラー
    """
    error_details = exc.errors()
    # 失敗ログの出力
    logger.error(f"SweaterDimensions の検証に失敗しました: {error_details}")
    
    # クライアントには、詳細なエラー情報を返す
    return JSONResponse(
        status_code=422,
        content={"detail": "input value is invalid.", "errors": error_details},
    )

# シェイプ（型紙）
class Shape:
    def __init__(self, path: Path, stitch_width: float, stitch_length: float):
        self.path = path
        self._stitch_width = stitch_width
        self._stitch_length = stitch_length

    def __getattr__(self, name):
        # クラスにないものはnp.ndarrayに投げる
        return getattr(self.drawing, name)

    @classmethod
    def body_from(cls, data, is_front:bool) -> 'Shape':
        """
        身頃の Shape を生成する

        Args:
            data (SweaterDimensions): 寸法データクラス
            is_front (bool): 前身頃または後身頃

        Returns:
            Shape: 生成された身頃のシェイプ


        """

        # 襟ぐり下がり
        length_of_neck_drop = data.length_of_back_neck_drop
        if is_front:
            length_of_neck_drop = data.length_of_front_neck_drop
            

        # 肩の水平な直線の長さ
        stitch_num_of_shoulder_drop = int(data.length_of_shoulder_drop / data.stitch_length)
        stitch_num_of_shoulder_width = int(data.width_of_shoulder / data.stitch_width)
        stitch_num_of_horizonal_shoulder_line = int((stitch_num_of_shoulder_width / stitch_num_of_shoulder_drop)/2)
        horizonal_shoulder_line_width = stitch_num_of_horizonal_shoulder_line * data.stitch_width

        # 身頃のパス
        path = parse_path(
            # 起点に移動 右の脇下
            f"M {0} {data.length_of_shoulder_drop + data.length_of_vertical_armhole} "

            # 袖ぐりの半分までの曲線
            f"c {data.width_of_horizontal_armhole},0 {data.width_of_horizontal_armhole},-{data.length_of_vertical_armhole / 2} {data.width_of_horizontal_armhole},-{data.length_of_vertical_armhole / 2} "

            # 左肩の左端までの垂直な直線
            f"v -{data.length_of_vertical_armhole / 2} "

            # 左肩の右端の少し前までの直線
            f"l {data.width_of_shoulder - horizonal_shoulder_line_width},-{data.length_of_shoulder_drop} "

            # 襟ぐりの左の上端までの水平な直線
            f"h {horizonal_shoulder_line_width} "

            # 襟ぐりの下端までの曲線
            f"c 0,{length_of_neck_drop} {data.width_of_neck / 2},{length_of_neck_drop} {data.width_of_neck / 2},{length_of_neck_drop} "

            # 襟ぐりの右の上端までの曲線
            f"c {data.width_of_neck / 2},0 {data.width_of_neck / 2},-{length_of_neck_drop} {data.width_of_neck / 2},-{length_of_neck_drop} "

            # 襟ぐりの右の上端から少し右への水平な直線
            f"h {horizonal_shoulder_line_width} "

            # 右肩の右端までの直線
            f"l {data.width_of_shoulder - horizonal_shoulder_line_width},{data.length_of_shoulder_drop} "

            # 右の襟ぐりの半分までの直線
            f"v {data.length_of_vertical_armhole / 2} "

            # 脇下までの曲線
            f"c 0,{data.length_of_vertical_armhole / 2} {data.width_of_horizontal_armhole},{data.length_of_vertical_armhole / 2} {data.width_of_horizontal_armhole},{data.length_of_vertical_armhole / 2} "

            # 裾の右の下端までの垂直な直線
            f"v {data.length_of_body_side + data.length_of_ribbed_hem} "

            # 裾の端から端までの水平な直線
            f"h {-data.width_of_body}"

            # 始点まで
            f"Z"
        )
        
        return cls(path, data.stitch_width, data.stitch_length)

    @classmethod
    def sleeve_from(cls, data: SweaterDimensions) -> 'Shape':
        """
        袖のシェイプ（SVG）を生成する

        Args:
            data (SweaterDimensions): 検証済みの寸法データクラス

        Returns:
            Shape: 生成された袖のシェイプ

        """

        # 袖のパス
        path = parse_path(
            # 始点 袖山の左端まで移動する
            f"M {0},{data.length_of_sleeve_cap} "

            # 袖山のトップまでの曲線
            f" c {data.width_of_sleeve/2},{0} {data.width_of_sleeve/2},{-data.length_of_sleeve_cap} {data.width_of_sleeve},{-data.length_of_sleeve_cap} "

            # 袖山の右端までの曲線
            f" c {data.width_of_sleeve/2},{0} {data.width_of_sleeve/2},{data.length_of_sleeve_cap} {data.width_of_sleeve},{data.length_of_sleeve_cap} "

            # 右の袖の上端までの斜めの直線
            f"l {data.width_of_cuff - data.width_of_sleeve},{data.length_of_sleeve_side} "

            # 右の袖の上端から下端までの垂直な直線
            f"v {data.length_of_ribbed_cuff} "

            # 袖の下端の端から端までの水平な直線
            f"h {-data.width_of_cuff * 2} "

            # 左の袖の下端のから上端での垂直な直線
            f"v {-data.length_of_ribbed_cuff} "

            # 始点まで
            f"Z"
        )

        return cls(path, data.stitch_width, data.stitch_length)

    @property
    def stitch_width(self):
        return self._stitch_width

    @property
    def stitch_length(self):
        return self._stitch_length

# チャート（編み図）
class Chart:
    def __init__(self, array: np.ndarray, stitch_width: float, stitch_length: float):
        self.array = array
        self._stitch_width = stitch_width
        self._stitch_length = stitch_length

    def __getattr__(self, name):
        # クラスにないものはnp.ndarrayに投げる
        return getattr(self.array, name)

    @classmethod
    def from_shape(cls, shape: Shape) -> 'Chart':
        """
        Shape の Path オブジェクトを元に Chart を生成します

        まず、Path を Shapely の Polygon オブジェクトに変換します

        次に、縦に並んだ2つのグリッドセル（判定範囲）の中心（判定点）がPolygonオブジェクトの
        内部に存在するかどうかを判定し二次元配列を生成します。
        左右の端で折り返し位置をずらすために、ビューボックスの中心を対称軸として
        右半分と左半分で判定範囲をずらします。

        編み目記号を挿入します。

        Args:
            shape: Shape

        Returns:
            np.ndarray: チャートの二次元配列
        """
        logger.debug(f"_convert_shape_to_chart() is called")

        # ビューボックスのサイズを取得する
        viewbox = shape.shape.bbox()
        width = viewbox[2] - viewbox[0]
        height = viewbox[3] - viewbox[1]

        # グリッドセルの縦横の数を計算する
        num_grid_width = int(width / shape.stitch_width)
        num_grid_height = int(height / (shape.stitch_length))
        num_grid_width_half = int(num_grid_width / 2) #対称軸の位置
        logger.debug(f"number of grid: num_grid_width={num_grid_width} num_grid_height={num_grid_height} num_grid_width_half={num_grid_width_half}")

        # グリッドセルと同じ行列数の配列を生成
        grid_array = np.zeros((num_grid_height, num_grid_width), dtype=np.int8)
        logger.debug(f"grid_array is created")

        # 元のSVGからすべてのパスと長方形を抽出してポリゴンに変換
        svg_str = shape.path.d()
        root = ElementTree.fromstring(svg_str)
        namespaces = {'svg': 'http://www.w3.org/2000/svg'}
        polygons = []

        # パス要素からポリゴンを生成
        path_elements = root.findall('.//svg:path', namespaces)
        for i, path_element in enumerate(path_elements):
            try:
                path_d = path_element.attrib['d']
                path = parse_path(path_d)
                polygon_points = []
            except Exception as e:
                logger.warning(f"Could not parse path at index {i} due to {e}")
                continue

            # パスを線分に分割して点を取得
            num_samples = 100 # サンプリング数を増やすことでより正確なポリゴン化を行う
            for segment in path:
                if isinstance(segment, (Line, CubicBezier, QuadraticBezier)):
                    for i in range(num_samples + 1):
                        t = i / num_samples
                        p = segment.point(t)
                        polygon_points.append((p.real, p.imag))
                else: pass
            # 閉じたパスの場合のみポリゴンとして追加
            if path.isclosed() and len(polygon_points) >= 3:
                try:
                    # TopologyException を回避するための裏技
                    polygons.append(Polygon(polygon_points).buffer(0))
                except Exception as e:
                    logger.warning(f"Could not buffer polygon at index {i} due to {e}")
            else: pass


        # 長方形要素からポリゴンを生成
        rect_elements = root.findall('.//svg:rect', namespaces)
        for i, rect_element in enumerate(rect_elements):
            try:
                x = float(rect_element.attrib.get('x', 0))
                y = float(rect_element.attrib.get('y', 0))
                w = float(rect_element.attrib['width'])
                h = float(rect_element.attrib['height'])
                polygon = Polygon([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])
                polygons.append(polygon)
            except Exception as e:
                logger.warning(f"Could not parse rect element at index[{i}] due to {e}")
                continue

        if not polygons:
            # 形状が一つも抽出されなかった場合はNoneを返す
            logger.warning(f"No polygons found in SVG")
            return None
        else:
            # 抽出した全てのポリゴンを結合
            combined_shape = unary_union(polygons)
            logger.debug(f"combined_shape is created from {len(polygons)} polygons")

        # 1目の縦横の長さに対応したグリッドセルの中心が内側かどうかは判定する
        for y_index, y_coordinate in enumerate(np.arange(0, height, shape.stitch_length)):
            for x_index, x_coordinate in enumerate(np.arange(0, width, shape.stitch_width)):
                # 判定点
                point = Point(float(x_coordinate + shape.stitch_width / 2), float(y_coordinate + shape.stitch_length / 2))
                # 右側の判定点が結合された形状の内部にあるか判定
                if combined_shape.contains(point):
                    # 内部にある場合、グリッドセルを描画
                    grid_array[y_index, x_index] = Symbol.KNIT.number

        logger.debug(f"grid_array is generated: shape{grid_array.shape[0]} length_of_x={grid_array.shape[1]}")
        return cls(grid_array, shape.stitch_width, shape.stitch_length)

    @property
    def stitch_width(self):
        return self._stitch_width

    @property
    def stitch_length(self):
        return self._stitch_length

    def chunk_rows_by_two(self) -> np.ndarray:
        result = self.array.copy()
        rows, cols = self.array.shape
        mid = cols // 2
        
        # --- 左半分: 1-2行目, 3-4行目... でペア ---
        # 上側(above): 0, 2, 4... 行目
        # 下側(below): 1, 3, 5... 行目
        left_above = result[0:rows-1:2, :mid]
        left_below = self.array[1:rows:2, :mid]
        left_above[left_below == Symbol.KNIT] = Symbol.KNIT

        # --- 右半分: 2-3行目, 4-5行目... でペア ---
        # 上側(above): 1, 3, 5... 行目
        # 下側(below): 2, 4, 6... 行目
        # ※奇数列対応のため、開始位置を mid からにする
        right_above = result[1:rows-1:2, mid:]
        right_below = self.array[2:rows:2, mid:]
        right_above[right_below == Symbol.KNIT] = Symbol.KNIT

        self.array = result
        return result

    def insert_none_row_to_top(self):
        result = self.array.copy()
        result = np.insert(result, 0, Symbol.NONE.number, axis=0)
        self.array = result
        return result

    def insert_rib_below(self, start_row: int) -> np.ndarray:
        """
        start_row より下の行においてゴム編み(表編みと裏編みの交互)を挿入する
        """
        result = self.array.copy()
        
        # 指定行より下の行かつインデックスが1から1列おきのスライス
        target_area = result[start_row + 1:, 1::2]
        
        # target の場所を replacement に書き換え
        target_area[target_area == Symbol.KNIT] = Symbol.PURL
        
        self.array = result
        return result

    def insert_cast_off(self):
        """
        下のセルが Symbol.KNIT かつ上のセルが Symbol.NONE である場合に
        上のセルを Symbol.CAST_OFF で書き換える
        """
        result = self.array.copy()
        
        bottom = self.array[1:]   # 下の行
        top = self.array[:-1]  # 上の行
        
        # 書き換え対象
        target_above = result[:-1]
        
        # 下のセルが Symbol.KNIT かつ上のセルが Symbol.NONE である
        mask = (bottom == Symbol.KNIT) & (top == Symbol.NONE)
        
        # 書き換え
        target_above[mask] = Symbol.CAST_OFF
        
        self.array = result

        return result

    def insert_k2tog_and_kks(self, target_side: Side, target, replacement) -> np.ndarray:
        """
        左右に並んだペアのうち target_side だけが target である場合にその値を replacement に書き換える
        """
        result = self.array.copy()
        cols = self.array[1]
        
        # 比較対象となる「左側の列集合」と「右側の列集合」を定義
        # 偶数番目の列 (0, 2, 4...) を左、奇数番目の列 (1, 3, 5...) を右とするペア
        left_cols = self.array[:, :-1]
        right_cols = self.array[:, 1:]
        
        # 左が Symbol.KNIT かつ右が Symbol.NONE
        mask = (left_cols == Symbol.KNIT) & (right_cols == Symbol.NONE)
        result[:, :-1][mask] = Symbol.K2TOG
    
        # 右が Symbol.NONE かつ Symbol.KNIT
        mask = (right_cols == Symbol.NONE) & (left_cols == Symbol.KNIT)
        result[:, 1:][mask] = Symbol.SSK
        
        self.array = result
        return result

    def insert_k1b(self) -> np.ndarray:
        """
        2x2のグリッドにおいて
        - 左下だけが Symbol.KNIT なら、右上を Symbol.K1B に置換
        - 右下だけが Symbol.KNIT なら、左上を Symbol.K1B に置換
        """
        result = self.array.copy()
        rows, cols = self.array.shape

        # 2x2ブロックを扱うため、行・列ともにステップ2でスライス
        # [上段, 左側], [上段, 右側], [下段, 左側], [下段, 右側] のビューを作成
        tl = self.array[:-1, :-1]
        tr = self.array[:-1, 1:]
        bl = self.array[1:,  :-1]
        br = self.array[1:,   1:]

        # 書き換え用のビュー
        res_tl = result[:-1, :-1]
        res_tr = result[:-1, 1:]

        # 左下だけが Symbol.KNIT なら右上をSymbol.K1Bに置換
        mask = (
            (tl == Symbol.NONE) & (tr == Symbol.NONE) &
            (bl == Symbol.KNIT) & (br == Symbol.NONE)
        )
        res_tr[mask] = Symbol.K1B

        # 右下だけが Symbol.KNIT なら左上をSymbol.K1Bに置換
        mask = (
            (tl == Symbol.NONE) & (tr == Symbol.NONE) &
            (bl == Symbol.NONE) & (br == Symbol.KNIT)
        )
        res_tl[mask] = Symbol.K1B

        self.array = result
        return result       

@app.post("/generate_sweater_chart", response_description="generated file")
async def main(data: SweaterDimensions, is_debug=False):
    """
    Pydanticモデルで受け取ったデータから生成したファイルを送信する
    
    Args:
        data (SweaterDimensions): 検証済みの寸法データクラス
    """

    file_path = generate_file(data)

    background = BackgroundTasks()
    background.add_task(cleanup_file(file_path))

    try:
        # 1. コアロジックを実行し、一時ファイルのパスを取得
        file_path = generate_file(data)
        
        # 2. FileResponseでファイルをクライアントに送信
        return FileResponse(
            path=file_path, 
            filename="sweater_pattern_data.csv",
            media_type="text/csv", # TODO .xlsx .pdf
            background=background # 送信後にファイルを削除するタスクを設定
        )

    except Exception as e:
        if file_path and os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"ファイル生成中にエラーが発生しました: {str(e)}")

def cleanup_file(file_path: str):
    import os
    def _cleanup():
        # ファイルが存在することを確認してから削除
        if os.path.exists(file_path):
            os.remove(file_path)
    return _cleanup
    
    if data.body_shape_type is BodyShapeType.STANDARD:
        front_body_shape = generate_shape_of_sweater_body(data)

    def __call__(self):
        import os
        if os.path.exists(self.file_path):
            os.remove(self.file_path)
            print(f"一時ファイル {self.file_path} を削除しました。")
        else:
            print(f"一時ファイル {self.file_path} は既に存在しませんでした。")

def generate_file(data: SweaterDimensions) -> str:
    """
    データから生成した一時ファイルのパスを返す

    Args:
        data (SweaterDimensions): 検証済みの寸法データクラス

    Returns:
        str: 一時ファイルのパス
    
    """
    # TODO メイン処理
    front_body_shape = Shape.body_from(data, is_front=True)
    back_body_shape = Shape.body_from(data, is_front=False)
    sleeve_shape = Shape.sleeve_from(data)

    front_body_chart = Chart.from_shape(front_body_shape)
    back_body_chart = Chart.from_shape(back_body_shape)
    sleeve_chart = Chart.from_shape(sleeve_shape)

    start_row_of_ribbed_hem = int((data.length_of_body - data.length_of_ribbed_hem) / data.stitch_length)
    start_row_of_ribbed_cuff = int((data.length_of_sleeve - data.length_of_ribbed_cuff) / data.stitch_length)

    (
        front_body_chart
            .replace_vertical_stripes_below(front_body_chart, start_row_of_ribbed_hem, Symbol.KNIT.number, Symbol.PURL.number)
    )

    (
        back_body_chart
            .replace_vertical_stripes_below(back_body_chart, start_row_of_ribbed_hem, Symbol.KNIT.number, Symbol.PURL.number)
    )

    (
        sleeve_chart
            .replace_vertical_stripes_below(sleeve_chart, start_row_of_ribbed_cuff, Symbol.KNIT.number, Symbol.PURL.number)
    )




    tmp_file = tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.csv', encoding='utf-8', newline='')
    return tmp_file.name
    