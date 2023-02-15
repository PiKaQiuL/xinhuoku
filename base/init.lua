_G.cmsg_pack = base.pack  -- 给pack设置msg_pack别名, 为了和客户端同步

base.tsc = require 'base.lualib_bundle'
require 'base.table_attr'
require 'base.log'
require 'base.math'
require 'base.selector'
require 'base.event'
require 'base.timer'
require 'base.utility'
require 'base.point'
require 'base.scene_point'
require 'base.position'
require 'base.line'
require 'base.circle'
require 'base.rect'
require 'base.array'
require 'base.hashtable'
require 'base.group'
require 'base.obj_check'
require 'base.trigger'
require 'base.player'
require 'base.team'
require 'base.unit'
require 'base.state_machine'
require 'base.damage'
require 'base.heal'
require 'base.lni'
require 'base.cheat'
require 'base.force'
require 'base.old_junk'
require 'base.shop'
require 'base.table'
require 'base.eff'
require 'base.eff_param'
require 'base.cmd_result'
require 'base.target_filter'
require 'base.channeler'
require 'base.skill'
require 'base.buff'
require 'base.snapshot'
require 'base.effect'
require 'base.response'
require 'base.item'
require 'base.inventory'
require 'base.loot'
require 'base.co'
require 'base.class'
require 'base.exception'
require 'base.promise'
require 'base.try'
require 'base.validator'
require 'base.auxiliary'

require 'base.actor'

require 'base.game'
require 'base.rpc'
require 'base.loot_pool'
require 'base.detection'
require 'base.trigger_editor_v2'
require 'base.ad'
require_folder 'base.base_lua_plus'

_G.json = require 'base.json_decode'  -- 客户端的json是全局的, 所以这里也全局吧

require 'base.load_done' --base加载完之后做的一些工作
