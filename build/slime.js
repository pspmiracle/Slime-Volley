var Slime;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
Slime = (function() {
  __extends(Slime, Sprite);
  function Slime(x, y, color, img) {
    this.x = x;
    this.y = y;
    this.color = color;
    this.img = img;
    this.radius = 31;
    this.isP2 = false;
    Slime.__super__.constructor.call(this, this.x, this.y, this.radius * 2, this.radius * 2);
  }
  Slime.prototype.createBody = function() {
    this.fixture = new Box2D.Dynamics.b2FixtureDef();
    this.fixture.density = 1.0;
    this.fixture.friction = 1.0;
    this.fixture.restitution = 0;
    this.fixture.shape = new Box2D.Collision.Shapes.b2CircleShape(this.radius);
    this.body = new Box2D.Dynamics.b2BodyDef();
    this.body.type = Box2D.Dynamics.b2Body.b2_dynamicBody;
    return this.body.position.Set(this.x, this.y);
  };
  Slime.prototype.handleInput = function(input, world) {
    var bottom, pNum, y;
    if (this.m_body) {
      y = world.height - this.m_body.GetPosition().y;
    }
    pNum = this.isP2 ? 1 : 0;
    bottom = 100;
    if (input.left(pNum)) {
      this.m_body.m_linearVelocity.x = -40;
      this.m_body.SetAwake(true);
    }
    if (input.right(pNum)) {
      this.m_body.m_linearVelocity.x = 40;
      this.m_body.SetAwake(true);
    }
    if (input.up(pNum)) {
      if (y < bottom) {
        this.m_body.m_linearVelocity.y = -100;
        this.m_body.SetAwake(true);
      }
    }
    if (input.down(pNum)) {
      if (this.m_body.m_linearVelocity.y > 0 && y > bottom) {
        return this.m_body.m_linearVelocity.y *= 1.5;
      }
    } else if (this.m_body && y < bottom) {
      return this.m_body.m_linearVelocity.x /= 1.1;
    }
  };
  Slime.prototype.draw = function(ctx) {
    var ballVec, eyeVec, localEyeVec, offsetX, offsetY;
    ctx.fillStyle = '#000';
    ctx.fillRect(this.x, this.y, 3, 3);
    ctx.drawImage(this.img, this.x - this.radius - 1, this.y - this.radius);
    offsetY = this.radius / 2.0;
    offsetX = offsetY * .95;
    if (this.isP2) {
      offsetX = -offsetX;
    }
    eyeVec = new Box2D.Common.Math.b2Vec2(this.x + offsetX, this.y - offsetY);
    localEyeVec = new Box2D.Common.Math.b2Vec2(offsetX, offsetY);
    ballVec = new Box2D.Common.Math.b2Vec2(this.ball.x, this.ball.y);
    ballVec.Subtract(eyeVec);
    ballVec.y = -ballVec.y;
    ballVec.Normalize();
    ballVec.Multiply(3);
    ballVec.Add(localEyeVec);
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.arc(this.x + ballVec.x, this.y - ballVec.y, 2, 0, Math.PI * 2, true);
    ctx.closePath();
    return ctx.fill();
  };
  return Slime;
})();